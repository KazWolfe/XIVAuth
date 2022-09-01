# Borrowed from @mattantonelli and FFXIVCollect
# Thank you for dealing with this hell so that I don't have to.

module Lodestone
  ROOT_URL = 'https://na.finalfantasyxiv.com/lodestone'.freeze
  DESKTOP_USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
    'Chrome/104.0.0.0 Safari/537.36'
  MOBILE_USER_AGENT = 'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) ' \
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Mobile Safari/537.36'.freeze
  

  extend self

  def character(character_id)
    character_meta = profile(character_id)
    Rails.logger.info("Fetched character ID #{character_id} from Lodestone", character_meta)
    character_meta
  end

  def verified?(character_id, code)
    meta = character(character_id)
    meta[:bio].include?(code)
  end

  def character_with_verification(character_id, code)
    meta = character(character_id)

    meta[:verified] = meta[:bio].include?(code)

    meta
  end

  private

  def profile(character_id)
    doc = character_document(character_id: character_id)

    {
      id: character_id,
      name: doc.at_css('.frame__chara__name').text,
      server: doc.at_css('.frame__chara__world').text[/^\w+/],
      bio: doc.css('.character__character_profile').text,
      data_center: doc.at_css('.frame__chara__world').text.gsub(/.*\[(\w+)\]/, '\1'),
      portrait: doc.at_css('.character__detail__image > a > img').attributes['src'].value,
      avatar: doc.at_css('.frame__chara__face > img').attributes['src'].value,
      last_parsed: Time.now
    }
  end

  def character_document(character_id: nil, params: {})
    url = [ROOT_URL, 'character', character_id].compact.join('/')

    begin
      Nokogiri::HTML.parse(RestClient.get(url, user_agent: MOBILE_USER_AGENT, params: params))
    rescue RestClient::NotFound
      # Ignore 404s on missing collections
    end
  end

  def element_id(element)
    element.attributes['href'].value.match(%r{(\d+)/$})[1].to_i
  end

  def element_time(element)
    time = element.at_css('.entry__activity__time').text.match(/ldst_strftime\((\d+)/)[1]
    Time.at(time.to_i).to_formatted_s(:db)
  end
end

