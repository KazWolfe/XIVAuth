class FFXIV::Character < ApplicationRecord

  def lodestone_url(region = 'na')
    "https://#{region}.finalfantasyxiv.com/lodestone/character/#{lodestone_id}"
  end

  def home_with_datacenter
    "#{home_world} [#{data_center}]"
  end

  def refresh_from_lodestone(lodestone_data = nil)
    lodestone_data ||= LodestoneManager::CharacterFetcher.call(lodestone_id)

    self.name = lodestone_data[:name]
    self.home_world = lodestone_data[:world]
    self.data_center = lodestone_data[:data_center]
    self.avatar_url = lodestone_data[:avatar]
    self.portrait_url = lodestone_data[:portrait]
  end

  def self.for_lodestone_id(lodestone_id)
    existing = find_by_lodestone_id(lodestone_id)
    return existing if existing.present?

    character = new(lodestone_id:)
    character.refresh_from_lodestone
    character.save!

    character
  end
end
