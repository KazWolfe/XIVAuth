class FFXIV::LodestoneProfile
  include ActiveModel::API

  class LodestoneProfileInvalid < StandardError; end
  class LodestoneCharacterHidden < LodestoneProfileInvalid; end
  class LodestoneProfilePrivate < LodestoneProfileInvalid; end

  ROOT_URL = "https://na.finalfantasyxiv.com/lodestone".freeze
  DESKTOP_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) " \
    "Chrome/104.0.0.0 Safari/537.36".freeze
  MOBILE_USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, " \
    "like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1".freeze

  FREE_TRIAL_LEVEL_CAP = 70
  FAILURE_REASONS = [ :unspecified, :hidden_character, :profile_private, :not_found ]

  attr_reader :id, :last_parsed

  attr_accessor :failure_reason

  validate :character_exists?
  validate :character_visible?
  validate :character_profile_visible?

  def initialize(lodestone_id)
    super()

    @id = lodestone_id

    url = [ROOT_URL, "character", lodestone_id].compact.join("/")
    @request = Faraday.new(headers: { user_agent: DESKTOP_USER_AGENT }).get(url)
    @doc = Nokogiri::HTML.parse(@request.body)

    @last_parsed = Time.now
  end

  def name
    @name ||= @doc.at_css(".frame__chara__name").text
  end

  def title
    @title ||= @doc.at_css(".frame__chara__title")&.text
  end

  def world
    @world ||= @doc.at_css(".frame__chara__world").text[/^\w+/]
  end

  def datacenter
    @datacenter ||= @doc.at_css(".frame__chara__world").text.gsub(/.*\[(\w+)\]/, '\1')
  end

  def race
    @race ||= rcg_data.children.first.text
  end

  def clan
    @clan ||= rcg_data.children.last.text.split("/").first.strip
  end

  def gender
    @gender ||= rcg_data.children.last.text.split("/").last.strip == "♂" ? :male : :female
  end

  def bio
    @bio ||= @doc.css(".character__selfintroduction").text
  end

  def portrait
    @portrait ||= @doc.at_css(".character__detail__image > a > img").attributes["src"].value
  end

  def avatar
    @avatar ||= @doc.at_css(".frame__chara__face > img").attributes["src"].value
  end

  def free_company
    return @fc_info if @fc_info.present?

    element = @doc.at_css(".character__freecompany__name > h4 > a")
    return nil unless element

    @fc_info = {
      name: element.text,
      id: element.attributes["href"].value&.split("/")&.last&.to_i
    }
  end

  def class_levels
    return @class_levels if @class_levels.present?

    @class_levels = { }

    ary = @doc.css(".character__level__list > ul > li")
    return @class_levels unless ary.count.positive?

    ary.each do |it|
      name = ary.at_css("img")&.attributes["data-tooltip"]&.value
      level = it.text

      next unless name.present? && level.present? && level != "-"

      @class_levels[name] = level.to_i
    end

    @class_levels
  end

  # Check if this character is known to be paid. Returns true heuristically.
  # A false value does *not* indicate that this is a free trial character.
  def paid_character?
    self.free_company.present? || self.class_levels.values.any? { |x| x > FREE_TRIAL_LEVEL_CAP }
  end

  def character_profile_visible?
    unless (is_visible = !@doc.at_css(".character__content")&.text&.include?("This character's profile is private."))
      errors.add(:id, "Specified character's profile information is private.")
      self.failure_reason = :private_profile
    end

    is_visible
  end

  def character_visible?
    unless (is_visible = !((@request.status == 403) && (@doc.at_css(".error__heading")&.text == "Access Restricted")))
      errors.add(:id, "Specified character is private.") unless is_visible
      self.failure_reason = :hidden_character
    end

    is_visible
  end

  def character_exists?
    unless (exists = !http_404?(@request, @doc))
      errors.add(:id, "Could not find character by specified ID") if http_404?(@request, @doc) unless exists
      self.failure_reason = :not_found
    end

    exists
  end

  private def rcg_data
    @rcg_data ||= @doc.css(".character__profile__data__detail > .character-block > .character-block__box " \
                            "> .character-block__name").first
  end

  private def http_404?(request, doc)
    return true if request.status == 404
    return true if doc.at_css(".error__heading")&.text == "Page not found."

    false
  end
end
