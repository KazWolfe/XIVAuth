class CharacterBan < ApplicationRecord
  belongs_to :character, polymorphic: true
end
