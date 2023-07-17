require 'utilities/base32'

class CharacterRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :character, class_name: 'FFXIV::Character'

  validates :character_id, uniqueness: { scope: [:user_id], message: 'is already registered to you!' }
  validates_uniqueness_of :character_id,
                          conditions: -> { where.not(verified_at: nil) },
                          message: 'has already been verified.'

  validates_associated :character, message: 'could not be found or is invalid.'

  attr_accessor :skip_ban_check
  validate :character_not_banned, unless: :skip_ban_check, on: :create

  validate :owner_can_create

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
  def verify!(clobber: false, send_email: false)
    transaction do
      other_registration = CharacterRegistration.verified.find_by(character_id:)

      if other_registration.present? && clobber
        logger.warn('Character verification was clobbered!', old: other_registration, new: self)
        other_registration.verified_at = nil
        other_registration.save!

        # TODO: Send an email to the losing user.
      end

      self.verified_at = DateTime.now
      save!
    rescue ActiveRecord::RecordInvalid
      self.verified_at = nil  # rollback record in memory
      raise
    end
  end

  def verification_key
    # TODO: Load secret from environment, don't use lodestone_id as it's not reusable (other models in future)
    secret = Rails.application.key_generator.generate_key('CharacterVerificationSecret')
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, "#{character.lodestone_id}###{user.id}")

    "XIVAUTH:#{Base32.encode(hmac).truncate(24, omission: '')}"
  end

  # Generates an "entangled ID", suitable for unique, consistent, and private identification of a single Character Registration.
  # This ID should be used for any authentication systems that want to verify based on character ID while ensuring user guarantees.
  def entangled_id(higher_order_id: nil)
    entanglement_key = "#{character.lodestone_id}###{user.id}"
    entanglement_key += "###{higher_order_id}" if higher_order_id.present?

    # TODO: Think of a better strategy for this
    secret = Rails.application.key_generator.generate_key('CharacterEntanglementSecret')
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret, entanglement_key)

    Base64.urlsafe_encode64(hmac, padding: false)
  end

  private
  
  def owner_can_create
    if user.character_registrations.unverified.count >= user.unverified_character_allowance
      errors.add(:user, 'has too many unverified characters.')
    end
  end
  
  def character_not_banned
    if character.ban.present? && !skip_ban_check
      errors.add(:character, 'is currently banned.')
    end
  end
end
