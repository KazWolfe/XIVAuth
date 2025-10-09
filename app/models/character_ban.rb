class CharacterBan < ApplicationRecord
  belongs_to :character, polymorphic: true

  validates :reason, presence: true
end
