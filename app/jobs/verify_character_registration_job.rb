class VerifyCharacterRegistrationJob < ApplicationJob
  class VerificationKeyMissingError < StandardError; end

  queue_as :default

  retry_on VerificationKeyMissingError, attempts: 3, wait: 2.minutes, jitter: 15.seconds

  # @param [CharacterRegistration] registration A character registration to verify
  def perform(registration)
    character = registration.character

    if registration.verified?
      Rails.logger.warn "CharacterRegistration #{registration.id} is already verified!"
      return
    end

    lodestone_data = FFXIV::LodestoneProfile.new(character.lodestone_id)

    # We're here, might as well save the character data we just fetched. Waste not!
    character.refresh_from_lodestone(lodestone_data)
    character.save!

    unless lodestone_data.bio.upcase.include? registration.verification_key
      raise VerifyCharacterRegistrationJob::VerificationKeyMissingError,
            "Verification failed for #{registration.id} - key was not found."
    end

    registration.verify!
    registration.save!
  end
end
