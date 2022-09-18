class OAuth::CleanupStaleRecordsJob < ApplicationJob
  queue_as :default

  def perform(*)
    clean_access_grants
    clean_access_tokens
  end

  def clean_access_grants(cutoff = 24.hours.ago)
    OAuth::AccessGrant.where(revoked_at: ..cutoff).in_batches(&:delete_all)
    OAuth::AccessGrant.where.not(expires_in: nil)
                      .where("(expires_in IS NOT NULL AND (created_at + expires_in * INTERVAL '1 second') < ?)", cutoff)
  end

  def clean_access_tokens(cutoff = 7.days.ago)
    OAuth::AccessToken.where(revoked_at: ..cutoff).in_batches(&:delete_all)
    OAuth::AccessToken.where(refresh_token: nil)
                      .where.not(expires_in: nil)
                      .where("(expires_in IS NOT NULL AND (created_at + expires_in * INTERVAL '1 second') < ?)", cutoff)
  end
end
