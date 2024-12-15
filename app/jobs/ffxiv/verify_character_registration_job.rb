class FFXIV::VerifyCharacterRegistrationJob < ApplicationJob
  class VerificationKeyMissingError < StandardError; end

  MAX_RETRY_ATTEMPTS = 3

  queue_as :ffxiv_lodestone_jobs

  retry_on(VerificationKeyMissingError, attempts: MAX_RETRY_ATTEMPTS, wait: 2.minutes, jitter: 15.seconds) do |job, error|
    job.report_result("verification_failed_codenotfound")
  end

  discard_on(StandardError) do |job, error|
    job.report_result("generic_failure")
    raise error
  end

  discard_on(FFXIV::LodestoneProfile::LodestoneProfileInvalid) do |job, error|
    logger.error("Invalid profile", error: error)
    job.report_result("verification_failed_invalid")
  end

  discard_on(FFXIV::LodestoneProfile::LodestoneCharacterHidden) do |job, error|
    job.report_result("verification_failed_hiddenchara")
  end

  discard_on(FFXIV::LodestoneProfile::LodestoneProfilePrivate) do |job, error|
    job.report_result("verification_failed_privateprofile")
  end

  # @param [CharacterRegistration] registration A character registration to verify
  def perform(registration)
    character = registration.character

    if registration.verified?
      logger.warn "CharacterRegistration #{registration.id} is already verified!"
      self.report_result("verification_success") # i, uh, guess?
      return
    end

    lodestone_data = FFXIV::LodestoneProfile.new(character.lodestone_id)

    raise FFXIV::LodestoneProfile::LodestoneCharacterHidden unless lodestone_data.character_visible?
    raise FFXIV::LodestoneProfile::LodestoneProfilePrivate unless lodestone_data.character_profile_visible?
    unless lodestone_data.valid?
      raise FFXIV::LodestoneProfile::LodestoneProfileInvalid, lodestone_data.errors
    end

    # We're here, might as well save the character data we just fetched. Waste not!
    character.refresh_from_lodestone(lodestone_data)
    character.save!

    if lodestone_data.bio.upcase.include? registration.verification_key
      registration.verify!("lodestone_code", clobber: true)
      self.report_result("verification_success")
      return
    end

    self.report_result("verification_retry")
    raise FFXIV::VerifyCharacterRegistrationJob::VerificationKeyMissingError,
          "Verification failed for #{registration.id} - key was not found."
  end

  def report_result(partial_name)
    registration = arguments[0]

    Turbo::StreamsChannel.broadcast_update_to(
      "VerifyCharacterRegistrationJob:#{self.job_id}",
      target: "character-registration-job:#{self.job_id}:content",
      partial: "character_registrations/verifications/modals/#{partial_name}",
      locals: { registration: registration, character: registration.character, job: self },
      attributes: { method: :morph }
    )
  end
end
