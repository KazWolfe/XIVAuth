# frozen_string_literal: true

class LodestoneManager::CharacterFetcher < ApplicationService
  ROOT_URL = 'https://na.finalfantasyxiv.com/lodestone'
  DESKTOP_USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
    'Chrome/104.0.0.0 Safari/537.36'
  MOBILE_USER_AGENT = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, ' \
    'like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1'

  attr_reader :lodestone_id

  def initialize(lodestone_id)
    super()

    @lodestone_id = lodestone_id
  end

  def call
    url = [ROOT_URL, 'character', @lodestone_id].compact.join('/')
    request = Faraday.get(url, headers: { user_agent: MOBILE_USER_AGENT })

    doc = Nokogiri::HTML.parse(request.body)

    {
      id: @lodestone_id,
      name: doc.at_css('.frame__chara__name').text,
      world: doc.at_css('.frame__chara__world').text[/^\w+/],
      bio: doc.css('.character__selfintroduction').text,
      data_center: doc.at_css('.frame__chara__world').text.gsub(/.*\[(\w+)\]/, '\1'),
      portrait: doc.at_css('.character__detail__image > a > img').attributes['src'].value,
      avatar: doc.at_css('.frame__chara__face > img').attributes['src'].value,
      last_parsed: Time.now
    }
  end
end
