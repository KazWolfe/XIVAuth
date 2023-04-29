class FFXIV::World < ApplicationRecord
  has_many :characters, :class_name => 'FFXIV::Character'
  
  def self.load_from_xivapi!
    worlds = FFXIV::XIVAPIService.worlds
    
    
  end
end
