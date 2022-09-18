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

  def verify!
    self.verified_at = DateTime.now
    self.save!
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

  def self.any_verified?(lodestone_id)
    Character.where(lodestone_id:).where.not(verified_at: nil).count.positive?
  end

  def self.verified_for_lodestone(lodestone_id)
    Character.where(lodestone_id:).where.not(verified_at: nil).first
  end
end
