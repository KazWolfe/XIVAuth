class FFXIV::LodestoneProfile
  include ActiveModel::API

  class LodestoneProfileInvalid < StandardError; end
  class LodestoneCharacterHidden < LodestoneProfileInvalid; end
  class LodestoneProfilePrivate < LodestoneProfileInvalid; end

  ROOT_URL = "https://na.finalfantasyxiv.com/lodestone".freeze
  DESKTOP_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) " \
    "Chrome/141.0.0.0 Safari/537.36 (compatible; XIVAuth-Verifier/1.0; +https://xivauth.net/)"
  ).freeze
  MOBILE_USER_AGENT = (
    "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 " \
    "(KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1 " \
    "(compatible; XIVAuth-Verifier/1.0; +https://xivauth.net/)"
  ).freeze
  XIVAUTH_SCRAPE_HEADER = "XIVAuth 1.0 Lodestone Parser - operations@xivauth.net".freeze

  FREE_TRIAL_LEVEL_CAP = 70
  FAILURE_REASONS = [ :unspecified, :hidden_character, :profile_private, :not_found ]

  attr_reader :id, :last_parsed

  attr_accessor :failure_reason

  validate :character_exists?
  validate :character_visible?
  validate :character_profile_visible?

  # Create a LodestoneProfile for the given character ID.
  # Supports injecting raw HTML for tests to avoid network I/O.
  #
  # @param lodestone_id [Integer,String]
  # @param html [String, nil] optional raw Lodestone HTML to parse
  # @param user_agent [String] optional UA to use on fetch
  def initialize(lodestone_id, html: nil, user_agent: DESKTOP_USER_AGENT)
    super()

    @id = lodestone_id
    @last_parsed = Time.now

    if html.present?
      # Allow dependency-free testing via fixtures.
      @request = OpenStruct.new(status: 200)
      @doc = Nokogiri::HTML.parse(html)
    else
      url = [ROOT_URL, "character", lodestone_id].compact.join("/")
      begin
        @request = Faraday.new(headers: { user_agent: user_agent, x_blame: XIVAUTH_SCRAPE_HEADER }).get(url)
        @doc = Nokogiri::HTML.parse(@request.body.to_s)
      rescue Faraday::Error => e
        # Network failure — surface a generic validation error but avoid raising here.
        @request = OpenStruct.new(status: 599, error: e)
        @doc = Nokogiri::HTML::Document.new
        errors.add(:base, "Unable to fetch Lodestone profile")
        self.failure_reason = :unspecified
      end
    end
  end

  # Basic identity and profile fields
  def name
    @name ||= @doc.at_css(".frame__chara__name")&.text.to_s.strip
  end

  def title
    @title ||= @doc.at_css(".frame__chara__title")&.text&.strip
  end

  def world
    return @world if defined?(@world)

    text = @doc.at_css(".frame__chara__world")&.text.to_s
    @world = text.split("[").first.to_s.strip
  end

  def datacenter
    return @datacenter if defined?(@datacenter)

    text = @doc.at_css(".frame__chara__world")&.text.to_s
    @datacenter = text[/\[(.*?)\]/, 1]&.strip
  end

  def race
    @race ||= rcg_data&.children&.first&.text.to_s.strip.presence
  end

  def clan
    @clan ||= rcg_data&.children&.last&.text.to_s.split("/")&.first&.strip
  end

  def gender
    # Gender is indicated with the symbol in the RCG block. Default to :female if unknown to preserve prior behavior.
    @gender ||= begin
      sym = rcg_data&.children&.last&.text.to_s.split("/")&.last&.strip
      sym == "♂" ? :male : :female
    end
  end

  def bio
    @bio ||= @doc.at_css(".character__selfintroduction")&.text.to_s
  end

  def portrait
    return @portrait if @portrait.present?

    node = @doc.at_css(".character__detail__image > a > img") || @doc.at_css(".character__detail__image img")
    @portrait = node&.[]("src")

    if @portrait.nil?
      # Fallback because we have predictable URLs.
      @portrait = avatar.sub("fc0.jpg", "fl0.jpg")
    end
    
    @portrait
  end

  def avatar
    # Small face icon in the header card
    @avatar ||= begin
      node = @doc.at_css(".frame__chara__face > img") || @doc.at_css(".frame__chara__face img")
      node&.[]("src")
    end
  end

  def free_company
    return @fc_info if @fc_info.present?

    element = @doc.at_css(".character__freecompany__name > h4 > a")
    return nil unless element

    href = element["href"].to_s
    fc_id = href[%r{/freecompany/(\d+)}, 1]&.to_i

    @fc_info = {
      name: element.text,
      id: fc_id
    }
  end

  # Parse the job/class levels displayed on the page.
  # Returns a Hash of "Name" => Integer level.
  def class_levels
    return @class_levels if @class_levels.present?

    @class_levels = {}

    li_nodes = @doc.css(".character__level__list > ul > li")
    return @class_levels unless li_nodes.any?

    li_nodes.each do |li|
      img = li.at_css("img")
      name = img&.[]("data-tooltip")
      level = li.text.to_s.strip
      next unless name.present? && level.present? && level != "-"

      @class_levels[name] = level.to_i
    end

    @class_levels
  end

  # Check if this character is known to be paid. Returns true heuristically.
  # A false value does *not* indicate that this is a free trial character.
  def paid_character?
    free_company.present? || class_levels.values.any? { |x| x > FREE_TRIAL_LEVEL_CAP }
  end

  # Visibility and existence checks (also validations)
  def character_profile_visible?
    private_text = @doc.at_css(".character__content")&.text
    is_visible = !(private_text&.include?("This character's profile is private."))

    unless is_visible
      self.failure_reason = :profile_private
    end

    is_visible
  end

  def character_visible?
    restricted = (
      (@request.respond_to?(:status) && @request.status == 403) ||
      (@doc.at_css(".error__heading")&.text == "Access Restricted")
    )
    is_visible = !restricted

    unless is_visible
      errors.add(:base, :hidden_character, message: "is marked as hidden or private.")
      self.failure_reason = :hidden_character
    end

    is_visible
  end

  def character_exists?
    exists = !http_404?(@request, @doc)

    unless exists
      errors.add(:base, :not_found, message: "could not be found using this ID.")
      self.failure_reason = :not_found
    end

    exists
  end

  # Additional, optional fields that may be useful for callers. These do not affect validation.
  def nameday
    # e.g., in the profile block under "+ Nameday"
    @nameday ||= @doc.at_css(".character__profile__data__detail .character-block__birth")&.text&.strip
  end

  def guardian
    # e.g., next to Nameday as "Guardian" with a name in character-block__name
    return @guardian if defined?(@guardian)

    guardian_block = @doc.css(".character__profile__data__detail .character-block").find do |blk|
      blk.at_css(".character-block__title")&.text == "Guardian"
    end
    @guardian = guardian_block&.at_css(".character-block__name")&.text&.strip
  end

  def city_state
    # e.g., block title "City-state"
    return @city_state if defined?(@city_state)

    cs_block = @doc.css(".character__profile__data__detail .character-block").find do |blk|
      blk.at_css(".character-block__title")&.text == "City-state"
    end
    @city_state = cs_block&.at_css(".character-block__box .character-block__name")&.text&.strip
  end

  def grand_company
    # e.g., block title "Grand Company" with text like "Immortal Flames / Flame Captain"
    return @grand_company if defined?(@grand_company)

    gc_block = @doc.css(".character__profile__data__detail .character-block").find do |blk|
      blk.at_css(".character-block__title")&.text == "Grand Company"
    end

    if gc_block
      raw = gc_block.at_css(".character-block__name")&.text.to_s
      company, rank = raw.split("/").map { |s| s&.strip }
      @grand_company = { company: company, rank: rank }.compact
    else
      @grand_company = nil
    end
  end

  def pvp_team
    # e.g., present as a block labeled PvP Team with a link
    return @pvp_team if defined?(@pvp_team)

    anchor = @doc.at_css(".character__pvpteam__name > h4 > a")
    if anchor
      href = anchor["href"].to_s
      team_id = href[%r{/pvpteam/([^/]+)}, 1]
      @pvp_team = {
        name: anchor.text,
        id: team_id
      }
    else
      @pvp_team = nil
    end
  end

  private

  def rcg_data
    @rcg_data ||= @doc.css(
      ".character__profile__data__detail > .character-block > .character-block__box > .character-block__name"
    ).first
  end

  def http_404?(request, doc)
    return true if request.respond_to?(:status) && request.status == 404
    return true if doc.at_css(".error__heading")&.text == "Page not found."

    false
  end
end
