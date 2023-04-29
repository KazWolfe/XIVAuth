class FFXIV::CharacterRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :character, class_name: 'FFXIV::Character'

  validates :character_id, uniqueness: true, if: :verified?

  scope :verified, -> { where.not(verified_at: nil) }

  # Check if this character has been verified by the owning user.
  def verified?
    verified_at.present?
  end

  # Mark this character instance as verified *and save.*
  # This method does not perform any verification logic; it will simply
  # mark the record as verified.
  def verify!(clobber: false, notify: false)
    other_verified = FFXIV::CharacterRegistration.verified_for_lodestone(character_id)

    FFXIV::CharacterRegistration.transaction do
      if other_verified.present?
        raise StandardError('Character was already verified and clobber not requested!') unless clobber

        Rails.logger.info "Removing verification from #{other_verified} as another verification " \
                          'was requested'
        other_verified.verified_at = nil
        other_verified.save!
      end

      self.verified_at = DateTime.now
      save!
    end

    if other_verified.present? && notify
      CharacterMailer.with(character: other_verified)
                     .security_character_verified_elsewhere.deliver_later
    end
  end

  # Generates a key to use for the verification system.
  # Unique to this character_id on this user.
  def verification_key
    hmac = OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      Rails.application.key_generator.generate_key('character_verification_key'),
      "#{character_id}###{user_id}"
    )

    "XIVAUTH:#{Base32.encode(hmac).truncate(24, omission: '')}"
  end

  # Generate an entangled ID, unique to the character_id on this specific user.
  # Provided so applications will have a consistent ID for character management
  # purposes (that is, even if this character is recreated and reverified, this
  # ID will be consistent). Applications using character auth should use this
  # ID instead of the actual returned ID of this object or the lodestone_id.
  def entangled_id
    hmac = OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      Rails.application.key_generator.generate_key('character_entanglement_key'),
      "#{character_id}###{user_id}"
    )

    Base64.urlsafe_encode64(hmac, padding: false)
  end

  # Generate a Lodestone URL for this character's registration.
  # @param s_region The region to use for this URL, uses the record's region if not set.
  def lodestone_url(s_region = region)
    "https://#{s_region}.finalfantasyxiv.com/lodestone/character/#{character_id}/"
  end

  # Find a verified registration for a specific Lodestone ID.
  # Handled by SQL query here instead of digging into the Character as we don't
  # necessarily know if a Character exists, and because double-queries make me sad.
  # @param lodestone_id The Lodestone ID of the character to check for.
  def self.verified_for_lodestone(lodestone_id)
    FFXIV::CharacterRegistration.where(character_id: lodestone_id)
                                .where.not(verified_at: nil)
                                .first
  end

  # Sugar to check if a character (by ID) was verified by anyone yet.
  # @see verified_for_lodestone
  # @param lodestone_id The Lodestone ID of the character to check for.
  def self.any_verified?(lodestone_id)
    FFXIV::CharacterRegistration.verified_for_lodestone(lodestone_id)
                                .present?
  end
end
