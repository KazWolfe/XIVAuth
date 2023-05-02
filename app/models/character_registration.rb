require 'utilities/base32'

class CharacterRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :character, class_name: 'FFXIV::Character'

  validates :character_id, uniqueness: { scope: [:user_id] }
  validates :character_id, uniqueness: true, if: :verified?

  scope :verified, -> { where.not(verified_at: nil) }

  def verified?
    verified_at.present?
  end

  def verify!
    # FIXME: This needs to handle the edge case of *other* registrations also being verified somehow.
    #        Clobber?

    self.verified_at = DateTime.now
  end

  def verification_key
    # TODO: Load secret from environment, don't use lodestone_id as it's not reusable (other models in future)
    digest = OpenSSL::Digest.new('sha256')
    hmac = OpenSSL::HMAC.digest(digest, 'secret', "#{character.lodestone_id}###{user.id}")
    hmac_s = Base32.encode(hmac).truncate(24, omission: '')

    "XIVAUTH:#{hmac_s}"
  end

  # Generates an "entangled ID", suitable for unique, consistent, and private identification of a single Character Registration.
  # This ID should be used for any authentication systems that want to verify based on character ID while ensuring user guarantees.
  def entangled_id(higher_order_id: nil)
    entanglement_key = "#{character.lodestone_id}###{user.id}"
    entanglement_key += "###{higher_order_id}" if higher_order_id.present?

    # TODO: Think of a better strategy for this
    digest = OpenSSL::Digest.new('sha1')
    hmac = OpenSSL::HMAC.digest(digest, 'NotQuantumEntanglement', entanglement_key)

    Base64.urlsafe_encode64(hmac, padding: false)
  end

  private
end
