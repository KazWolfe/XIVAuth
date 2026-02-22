require "utilities/crockford"

class FFXIV::VerifyCharacterRegistrationJob < ApplicationJob
  class VerificationKeyMissingError < StandardError; end

  MAX_RETRY_ATTEMPTS = 3

  queue_as :ffxiv_lodestone_jobs

  discard_on(StandardError) do |job, error|
    job.report_result("generic_failure")
    raise error
  end

  discard_on(ActiveJob::DeserializationError) do |_job, error|
    if error.cause.is_a?(ActiveRecord::RecordNotFound)
      logger.warn("CharacterRegistration is missing - was it deleted?", error: error.cause)
      next
    end

    raise error
  end

  discard_on(FFXIV::LodestoneProfile::LodestoneProfileInvalid) do |job, error|
    logger.error("Got invalid profile while attempting verification", error: error)
    job.report_result("verification_failed_invalid")

    failure_reason = error.respond_to?(:failure_reason) ? error.failure_reason : "unspecified"
    job.record_verify_metric("error_#{failure_reason}")
  end

  discard_on(FFXIV::LodestoneProfile::LodestoneCharacterHidden) do |job, _error|
    logger.warn("Could not verify CR #{job.arguments[0].id} - character was hidden.")
    job.report_result("verification_failed_hiddenchara")
    job.record_verify_metric("failure_character_hidden")
  end

  discard_on(FFXIV::LodestoneProfile::LodestoneProfilePrivate) do |job, _error|
    logger.warn("Could not verify CR #{job.arguments[0].id} - profile was private.")
    job.report_result("verification_failed_privateprofile")
    job.record_verify_metric("failure_profile_private")
  end

  retry_on(FFXIV::VerifyCharacterRegistrationJob::VerificationKeyMissingError, attempts: MAX_RETRY_ATTEMPTS,
wait: 2.minutes) do |job, _error|
    logger.warn("Could not verify CR #{job.arguments[0].id} - verification key was not found after multiple attempts.")
    job.report_result("verification_failed_codenotfound")
    job.record_verify_metric("failure_code_not_found")
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
    lodestone_data.validate

    raise FFXIV::LodestoneProfile::LodestoneCharacterHidden if lodestone_data.failure_reason == :hidden_character
    unless lodestone_data.failure_reason.nil? || lodestone_data.failure_reason == :profile_private
      raise FFXIV::LodestoneProfile::LodestoneProfileInvalid,
            failure_reason: lodestone_data.failure_reason,
            errors: lodestone_data.errors.as_json
    end

    # We're here, might as well save the character data we just fetched. Waste not!
    character.refresh_from_lodestone(lodestone_data)
    character.save!

    # Set after updating, since we still get a partial response.
    raise FFXIV::LodestoneProfile::LodestoneProfilePrivate if lodestone_data.failure_reason == :profile_private

    lodestone_data.bio.scan(CharacterRegistration::VERIFICATION_KEY_REGEX).each do |match|
      code = match.delete_prefix(CharacterRegistration::VERIFICATION_KEY_PREFIX)
      candidate = CharacterRegistration::VERIFICATION_KEY_PREFIX + Crockford.normalize(code).upcase

      next unless candidate == registration.verification_key

      registration.verify!("lodestone_code", clobber: true)
      self.report_result("verification_success")
      self.record_verify_metric("success")
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

  def record_verify_metric(result)
    return unless defined?(Sentry)

    registration = arguments[0]
    Sentry.metrics.count("xivauth.character.verify", value: 1, attributes: {
      "character.lodestone_id": registration.character.lodestone_id,
      "character.verification_result": result,

      "user.id": registration.user_id
    })
  end
end
