# frozen_string_literal: true

module FFXIV
  class LodestoneProfile

    ROOT_URL = 'https://na.finalfantasyxiv.com/lodestone'
    DESKTOP_USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
    'Chrome/104.0.0.0 Safari/537.36'
    MOBILE_USER_AGENT = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, ' \
    'like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1'

    attr_reader :id, :name, :world, :datacenter, :race, :clan, :gender, :bio, :portrait, :avatar, :last_parsed

    def initialize(lodestone_id)
      super()

      @id = lodestone_id

      url = [ROOT_URL, 'character', lodestone_id].compact.join('/')
      request = Faraday.new(headers: { user_agent: DESKTOP_USER_AGENT }).get(url)

      throw StandardError 'A character with this ID was not found.' if request.status == 404

      doc = Nokogiri::HTML.parse(request.body)

      parse!(doc)
    end

    private

    def parse!(doc)
      @name = doc.at_css('.frame__chara__name').text
      @title = doc.at_css('.frame__chara__title')&.text

      @world = doc.at_css('.frame__chara__world').text[/^\w+/]
      @datacenter = doc.at_css('.frame__chara__world').text.gsub(/.*\[(\w+)\]/, '\1')

      rcg_data = doc.css('.character__profile__data__detail > .character-block > .character-block__box ' \
                            '> .character-block__name').first

      @race = rcg_data.children.first.text
      @clan = rcg_data.children.last.text.split('/').first.strip
      @gender = rcg_data.children.last.text.split('/').last.strip == "♂" ? :male : :female

      @bio = doc.css('.character__selfintroduction').text
      @portrait = doc.at_css('.character__detail__image > a > img').attributes['src'].value
      @avatar = doc.at_css('.frame__chara__face > img').attributes['src'].value

      @last_parsed = Time.now
    end
  end
end
