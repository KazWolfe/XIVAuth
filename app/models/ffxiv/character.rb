class FFXIV::Character < ApplicationRecord
  validates :lodestone_id, presence: true, uniqueness: true
  validate :lodestone_data_ok?, on: :create  # failures during standard updates are handled differently.

  validates :name, presence: true
  validates :home_world, presence: true
  validates :data_center, presence: true

  validates :refresh_fail_reason,
            inclusion: FFXIV::LodestoneProfile::FAILURE_REASONS,
            allow_nil: true

  has_many :character_registrations, dependent: :destroy
  has_one :ban, as: :character, class_name: "CharacterBan", dependent: :destroy

  after_save :call_character_saves

  def lodestone_url(region = "na")
    "https://#{region}.finalfantasyxiv.com/lodestone/character/#{lodestone_id}"
  end

  def home_with_datacenter
    "#{home_world} [#{data_center}]"
  end

  def stale?(hours = 24, failed_refresh_timeout_mins = 15)
    updated_at <= hours.hours.ago || (refresh_fail_reason.present? && updated_at <= failed_refresh_timeout_mins.minutes.ago)
  end

  def verified?
    self.character_registrations.verified.present?
  end

  def verified_owner
    self.character_registrations.verified.first&.user
  end

  def refresh_fail_reason
    super&.downcase&.to_sym
  end

  def refresh_fail_reason=(reason)
    super(reason.to_s.upcase)
  end

  def refresh_from_lodestone(lodestone_data = nil)
    return if lodestone_id.nil? && lodestone_data.nil?

    @lodestone_data = lodestone_data || FFXIV::LodestoneProfile.new(lodestone_id)
    unless @lodestone_data.valid?
      self.refresh_fail_reason = @lodestone_data.failure_reason || :unspecified
      return
    end

    self.name = @lodestone_data.name
    self.home_world = @lodestone_data.world
    self.data_center = @lodestone_data.datacenter
    self.avatar_url = @lodestone_data.avatar
    self.portrait_url = @lodestone_data.portrait
  end

  def self.for_lodestone_id(lodestone_id)
    existing = find_by(lodestone_id: lodestone_id)
    return existing if existing.present?

    character = new(lodestone_id: lodestone_id)
    character.refresh_from_lodestone

    character
  end

  private def lodestone_data_ok?
    errors.merge!(@lodestone_data.errors) if @lodestone_data.present? && !@lodestone_data.valid?
  end

  private def call_character_saves
    character_registrations.in_batches.each_record do |record|
      record.run_callbacks(:save)
    end
  end
end
