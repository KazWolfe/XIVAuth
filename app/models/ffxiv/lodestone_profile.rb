# frozen_string_literal: true 

class FFXIV::LodestoneProfile
  include ActiveModel::API

  ROOT_URL = 'https://na.finalfantasyxiv.com/lodestone'
  DESKTOP_USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
    'Chrome/104.0.0.0 Safari/537.36'
  MOBILE_USER_AGENT = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, ' \
    'like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1'

  attr_reader :id, :last_parsed
  validate :character_exists?

  def initialize(lodestone_id)
    super()

    @id = lodestone_id

    url = [ROOT_URL, 'character', lodestone_id].compact.join('/')
    @request = Faraday.new(headers: { user_agent: DESKTOP_USER_AGENT }).get(url)
    @doc = Nokogiri::HTML.parse(@request.body)

    @last_parsed = Time.now
  end

  def name
    @name ||= @doc.at_css('.frame__chara__name').text
  end

  def title
    @title ||= @doc.at_css('.frame__chara__title')&.text
  end

  def world
    @world ||= @doc.at_css('.frame__chara__world').text[/^\w+/]
  end

  def datacenter
    @datacenter ||= @doc.at_css('.frame__chara__world').text.gsub(/.*\[(\w+)\]/, '\1')
  end

  def race
    @race ||= rcg_data.children.first.text
  end

  def clan
    @clan ||= rcg_data.children.last.text.split('/').first.strip
  end

  def gender
    @gender ||= rcg_data.children.last.text.split('/').last.strip == '♂' ? :male : :female
  end

  def bio
    @bio ||= @doc.css('.character__selfintroduction').text
  end

  def portrait
    @portrait ||= @doc.at_css('.character__detail__image > a > img').attributes['src'].value
  end

  def avatar
    @avatar ||= @doc.at_css('.frame__chara__face > img').attributes['src'].value
  end

  private

  def rcg_data
    @rcg_data ||= @doc.css('.character__profile__data__detail > .character-block > .character-block__box ' \
                            '> .character-block__name').first
  end

  def http_404?(request, doc)
    return true if request.status == 404
    return true if doc.at_css('.error__heading')&.text == 'Page not found.'

    false
  end

  def character_exists?
    errors.add(:id, 'Could not find character by specified ID') if http_404?(@request, @doc)
  end
end
