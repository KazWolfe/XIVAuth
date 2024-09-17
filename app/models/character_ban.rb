class CharacterBan < ApplicationRecord
  belongs_to :character, polymorphic: true

  validates_presence_of :reason
end
