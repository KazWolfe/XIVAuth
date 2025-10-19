
class Users::CleanupUnconfirmedUsersJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    do_cleanup
  end

  def do_cleanup(cutoff = 14.days.ago)
    User.where(confirmed_at: nil)
        .where(created_at: ..cutoff)
        .in_batches(&:destroy_all)
  end
end
