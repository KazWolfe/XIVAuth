class Character::CleanupStaleCharactersJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    do_cleanup
  end
  
  def do_cleanup(cutoff = 5.days.ago)
    Character.where(verified_at: nil)
             .where(created_at: ..cutoff)
             .in_batches(&:delete_all)
  end
end
