require 'utilities/base32'

class CharacterRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :character, class_name: 'FFXIV::Character'

  def verified?
    verified_at.present?
  end

  def verify!
    self.verified_at = DateTime.now
  end

  def verification_key
    # TODO: Load secret from environment, don't use lodestone_id as it's not reusable
    digest = OpenSSL::Digest.new('sha256')
    hmac = OpenSSL::HMAC.digest(digest, 'secret', "#{character.lodestone_id}###{user.id}")
    hmac_s = Base32.encode(hmac).truncate(24, omission: '')

    "XIVAUTH:#{hmac_s}"
  end

  private
end
