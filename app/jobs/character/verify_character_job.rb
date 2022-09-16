class Character::VerifyCharacterJob < ApplicationJob
  class VerificationFailedError < StandardError; end

  queue_as :character_verifications
  retry_on Character::VerifyCharacterJob::VerificationFailedError, wait: 2.minutes, attempts: 5

  def perform(*characters)
    characters.each do |character|
      if Lodestone.verified?(character.lodestone_id, character.verification_key)
        character.verify!
        character.save!
      else
        raise VerificationFailedError "Character did not have verification code present."
      end
    end
  end
end
