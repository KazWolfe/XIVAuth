class Character::SyncLodestoneJob < ApplicationJob
  queue_as :default

  def perform(*characters)
    characters.each do |character|
      character.retrieve_from_lodestone!
      character.save!
    end
  end
end
