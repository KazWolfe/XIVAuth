class Character::VerifyCharacterJob < ApplicationJob
  class VerificationFailedError < StandardError; end

  queue_as :lodestone_jobs
  retry_on Character::VerifyCharacterJob::VerificationFailedError, wait: 2.minutes, attempts: 5

  def perform(*characters)
    characters.each do |character|
      if character.verified?
        Rails.logger.warn 'Attempted to verify character, but they were already verified?!'
        next
      end

      if Character.any_verified? character.lodestone_id
        Rails.logger.warn 'Attempted to verify character, but it was already claimed.', character
        next
      end

      if Lodestone.verified?(character.lodestone_id, character.verification_key)
        character.verify!
        character.save!
      else
        raise VerificationFailedError 'Character did not have verification code present.'
      end
    end
  end
end
