class FFXIV::RefreshCharactersJob < ApplicationJob
  queue_as :ffxiv_lodestone_jobs
  
  # @param [Array<FFXIV::Character>] characters A list of characters to update in this job run
  def perform(*characters, force_refresh: false)
    characters.each do |character|
      if !force_refresh && (character.updated_at > 24.hours.ago)
        logger.info "Skipping refresh of character #{character.lodestone_id}, they're already fresh."
        next
      end

      character.refresh_from_lodestone
      character.save!
    end
  end
end
