class OAuth::CleanupStaleRecordsJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    clean_access_grants
    clean_access_tokens
    clean_permissible_policies
  end

  def clean_access_grants(cutoff = 24.hours.ago)
    OAuth::AccessGrant.where(revoked_at: ..cutoff).in_batches(&:destroy_all)
    OAuth::AccessGrant.where.not(expires_in: nil)
                      .where("(created_at + expires_in * INTERVAL '1 second') < ?", cutoff)
                      .in_batches(&:destroy_all)
  end

  def clean_access_tokens(cutoff = 7.days.ago)
    OAuth::AccessToken.where(revoked_at: ..cutoff).in_batches(&:destroy_all)
    OAuth::AccessToken.where(refresh_token: nil)
                      .where.not(expires_in: nil)
                      .where("(created_at + expires_in * INTERVAL '1 second') < ?", cutoff)
                      .in_batches(&:destroy_all)
  end

  def clean_permissible_policies
    OAuth::PermissiblePolicy.left_outer_joins(:access_tokens, :access_grants)
                            .where(oauth_access_tokens: { id: nil }, oauth_access_grants: { id: nil })
                            .in_batches(&:destroy_all)
  end
end
