class Character < ApplicationRecord
  belongs_to :user

  validates :lodestone_id, presence: true
  validates :lodestone_id, uniqueness: { scope: [:user_id] }

  # You may be wondering why I don't add validation to home_world or character_name. I am too.
  # These values will not always be available (as lodestone fetching is background), so there
  # may be a bit of a delay in getting them.

  default_scope { order(created_at: :asc) }
  scope :verified, -> { where.not(verified_at: nil) }

  def verified?
    self.verified_at.present?
  end

  def verify!(clobber: false, notify: false)

    if (vfc = Character.verified_for_lodestone(self.lodestone_id)).present?
      raise StandardError('Character was verified elsewhere and clobber was not requested') unless clobber

      Rails.logger.info "Removing verification from character #{vfc.id} as another verification was requested"
      vfc.verified_at = nil
      vfc.save!

      # TODO: send security alert email
    end

    self.verified_at = DateTime.now
    self.save!
  end

  def user_unique_id
    hmac = OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      Rails.application.key_generator.generate_key('chara_user_unique_key'),
      "#{self.id}###{self.user.id}"
    )

    Base64.urlsafe_encode64(hmac, padding: false)
  end

  def verification_key
    hmac = OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      Rails.application.key_generator.generate_key('character_verification_key'),
      "#{self.lodestone_id}###{self.user_id}"
    )

    "XIVAUTH:#{Base32.encode(hmac).truncate(24, omission: '')}"
  end

  def retrieve_from_lodestone!(do_verify: false)
    character_meta = Lodestone.character_with_verification(self.lodestone_id, self.verification_key)

    self.character_name = character_meta[:name]
    self.home_world = character_meta[:server]
    self.home_datacenter = character_meta[:data_center]
    self.avatar_url = character_meta[:avatar]

    self.verify! if do_verify && !self.verified? && character_meta[:verified]

    self.last_lodestone_update = character_meta[:last_parsed]
  end

  def as_json(options = nil)
    {
      id:, lodestone_id:, character_name:, home_datacenter:, home_world:, avatar_url:,
      verified: verified?, verification_key:,
      last_lodestone_update:, created_at:, updated_at:
    }
  end

  def self.any_verified?(lodestone_id)
    Character.where(lodestone_id:).where.not(verified_at: nil).count.positive?
  end

  def self.verified_for_lodestone(lodestone_id)
    Character.where(lodestone_id:).where.not(verified_at: nil).first
  end
end
