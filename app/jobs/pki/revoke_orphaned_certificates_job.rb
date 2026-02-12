class PKI::RevokeOrphanedCertificatesJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    do_revoke
  end

  def do_revoke
    now = Time.current
    attrs = { revoked_at: now, revocation_reason: "affiliation_changed" }

    count  = cr_orphans.update_all(attrs)
    count += user_orphans.update_all(attrs)

    logger.info("Revoked #{count} orphaned PKI certificates.")
  end

  private

  def cr_orphans
    PKI::IssuedCertificate.active
      .where(subject_type: "CharacterRegistration")
      .where.not(subject_id: CharacterRegistration.select(:id))
  end

  def user_orphans
    PKI::IssuedCertificate.active
      .where(subject_type: "User")
      .where.not(subject_id: User.select(:id))
  end
end