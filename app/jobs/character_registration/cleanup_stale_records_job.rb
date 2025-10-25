class CharacterRegistration::CleanupStaleRecordsJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    do_cleanup
  end

  def do_cleanup(cutoff = 7.days.ago)
    CharacterRegistration.where(verified_at: nil)
                         .where(created_at: ..cutoff)
                         .tap { |rel| logger.info("Scheduling #{rel.count} stale registrations for deletion.") }
                         .in_batches(&:destroy_all)
  end
end
