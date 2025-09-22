require "utilities/crockford"

# {CharacterRegistration} represents a mapping between a game character and a claim by any specific user.
# Character registrations are only considered "effective" if they have been verified in some way.
#
# @!attribute source [string] The original source of this character registration, often used if this character
#                             was imported from another site.
# @!attribute verification_type [string] The means by which this specific character was verified. Varies based on
#                                        character type and other factors.
class CharacterRegistration < ApplicationRecord

  VERIFICATION_KEY_PREFIX = "XIVAUTH:".freeze
  VERIFICATION_KEY_LENGTH = 24.freeze
  VERIFICATION_KEY_REGEX = /#{VERIFICATION_KEY_PREFIX}[#{Crockford::ENCODER.join("")}]{#{VERIFICATION_KEY_LENGTH}}/i

  belongs_to :user
  belongs_to :character, class_name: "FFXIV::Character"

  validates :character_id, uniqueness: { scope: [:user_id], message: "is already registered to you!" }
  validates_uniqueness_of :character_id,
                          conditions: -> { where.not(verified_at: nil) },
                          if: -> { verified_at != nil },
                          message: "has already been verified."

  validates_associated :character, message: "could not be found or is invalid."

  validates :verification_type, presence: true, if: -> { self.verified? }
  validates :verification_type, absence: true, unless: -> { self.verified? }

  attr_accessor :skip_ban_check

  validate :character_not_banned, unless: :skip_ban_check, on: :create
  validate :owner_can_create, on: :create

  after_save :broadcast_card_update

  scope :verified, -> { where.not(verified_at: nil) }
  scope :unverified, -> { where(verified_at: nil) }

  attr_accessor :character_key

  def verified?
    verified_at.present?
  end

  # Mark the targeted CharacterRegistration as verified, optionally unverifying any other registrations that may be present.
  # This method will attempt to save all modified CharacterRegistrations.
  # @param clobber [Boolean] When true, unverify the prior CharacterRegistration.
  # @param send_email [Boolean] When true, send an email to the prior owner if their character was clobbered.
  def verify!(verification_type, clobber: false, send_email: false)
    transaction do
      other_registration = CharacterRegistration.verified.find_by(character_id:)

      if other_registration.present? && clobber
        logger.warn("Character verification was clobbered!", old: other_registration, new: self)
        other_registration.unverify
        other_registration.save!

        # TODO: Send an email to the losing user.
      end

      self.verify(verification_type)
      save!
    rescue ActiveRecord::RecordInvalid
      self.unverify
      raise
    end
  end

  def verify(verification_type)
    self.verified_at = DateTime.now
    self.verification_type = verification_type
  end

  def unverify
    self.verified_at = nil
    self.verification_type = nil
  end

  def verification_key
    # TODO: Load secret from environment, don't use lodestone_id as it's not reusable (other models in future)
    secret = Rails.application.key_generator.generate_key("CharacterVerificationSecret")
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), secret, "#{character.lodestone_id}###{user.id}")

    "#{VERIFICATION_KEY_PREFIX}#{Crockford.encode_string(hmac)&.truncate(VERIFICATION_KEY_LENGTH, omission: '')}"
  end

  # Generates an "entangled ID", suitable for unique, consistent, and private identification of a single Character Registration.
  # This ID should be used for any authentication systems that want to verify based on character ID while ensuring user guarantees.
  def entangled_id(higher_order_id: nil)
    entanglement_key = "#{character.lodestone_id}###{user.id}"
    entanglement_key += "###{higher_order_id}" if higher_order_id.present?

    # TODO: Think of a better strategy for this
    secret = Rails.application.key_generator.generate_key("CharacterEntanglementSecret")
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha1"), secret, entanglement_key)

    Base64.urlsafe_encode64(hmac, padding: false)
  end

  def lodestone_url
    self.character.lodestone_url(self.extra_data&.fetch("region", nil))
  end

  def broadcast_card_update
    broadcast_replace_to(
      "UserStream:#{user.id}", :character_registrations,
      target: "character_registration_#{self.id}",
      partial: "character_registrations/character_card"
    )
  end

  private def owner_can_create
    if user.character_registrations.unverified.count >= user.unverified_character_allowance
      errors.add(:user, "has too many unverified characters.")
    end
  end

  private def character_not_banned
    errors.add(:character, "is currently banned.") if character.ban.present? && !skip_ban_check
  end
end
