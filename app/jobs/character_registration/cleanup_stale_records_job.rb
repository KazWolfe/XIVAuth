class CharacterRegistration::CleanupStaleRecordsJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    do_cleanup
  end

  def do_cleanup(cutoff = 7.days.ago)
    CharacterRegistration.where(verified_at: nil)
                         .where(created_at: ..cutoff)
                         .in_batches(&:delete_all)
  end
end
