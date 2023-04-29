class FFXIV::Character < ApplicationRecord
  has_many :registrations, class_name: 'FFXIV::CharacterRegistration'
  has_one :verified_registration, -> { where 'verified_at IS NOT NULL' },
          class_name: 'FFXIV::CharacterRegistration'
  
  belongs_to :home_world, class_name: 'FFXIV::World',
                          foreign_key: 'exd_id'

  def fetch_from_lodestone
    character_data = Lodestone.character(this.id)

    self.character_name = character_data[:name]
    self.avatar_url = character_data[:avatar]
  end

  # Helper method to check if a Character has been registered and verified to anyone.
  def verified?
    verified_registration.present?
  end
end
