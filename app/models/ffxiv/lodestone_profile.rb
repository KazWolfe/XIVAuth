class FFXIV::LodestoneProfile
  include ActiveModel::API

  class LodestoneProfileInvalid < StandardError; end
  class LodestoneCharacterHidden < LodestoneProfileInvalid; end
  class LodestoneProfilePrivate < LodestoneProfileInvalid; end

  FREE_TRIAL_LEVEL_CAP = 70
  FAILURE_REASONS = [ :unspecified, :hidden_character, :profile_private, :not_found ]

  attr_accessor :id, :last_parsed, :raw_data, :failure_reason

  validate :character_exists?
  validate :character_visible?
  validate :character_profile_public?

  # Create a LodestoneProfile for the given character ID.
  # Supports injecting raw JSON for tests to avoid network I/O.
  #
  # @param lodestone_id [Integer,String]
  # @param json_object
  def initialize(lodestone_id, json_object: nil)
    super()

    if json_object.nil?
      requestor = Faraday.new(headers: {
        "X-API-Key": Rails.application.credentials.dig(:flarestone, :api_key)
      })

      flarestone_base_url = Rails.application.credentials.dig(:flarestone, :host) || "https://flarestone.xivauth.net"

      request = requestor.get("#{flarestone_base_url}/character/#{lodestone_id}")
      json_object = JSON.parse(request.body)
    end

    self.raw_data = json_object
    self.id = lodestone_id
    self.last_parsed = Time.now
  end

  # The name of this character.
  def name
    self.raw_data["name"]
  end

  def title
    self.raw_data["title"]
  end

  def world
    self.raw_data["world"]
  end

  def datacenter
    self.raw_data["datacenter"]
  end

  # The URL of this character's avatar ("headshot") image.
  def avatar
    self.raw_data["headshotUrl"]
  end

  # The URL of this character's portrait (full body) image.
  def portrait
    self.raw_data["portraitUrl"] || avatar.sub("fc0.jpg", "fl0.jpg")
  end

  def bio
    self.raw_data["bio"]
  end

  def free_company
    fc_data = self.raw_data["freeCompany"]
    return nil if fc_data.nil?

    {
      name: fc_data["name"],
      id: fc_data["lodestoneUrl"].match(/\/(\d+)\//)[1].to_i
    }
  end

  def class_levels
    self.raw_data["levels"]
  end

  # Check if this character is known to be paid. Returns true heuristically.
  # A false value does not indicate that this is a free trial character.
  def paid_character?
    free_company&.present? || class_levels.values.any? { |x| x > FREE_TRIAL_LEVEL_CAP }
  end

  # Visibility and existence checks (also validations)
  def character_profile_public?
    profile_private = self.raw_data["_meta"]["resultCode"] == "profile_private"

    if profile_private
      self.failure_reason = :profile_private
    end

    !profile_private
  end

  def character_visible?
    character_hidden = self.raw_data["_meta"]["resultCode"] == "character_hidden"

    if character_hidden
      errors.add(:base, :hidden_character, message: "is marked as hidden or private.")
      self.failure_reason = :hidden_character
    end

    !character_hidden
  end

  def character_exists?
    not_found = self.raw_data["_meta"]["resultCode"] == "not_found"

    if not_found
      errors.add(:base, :not_found, message: "could not be found using this ID.")
      self.failure_reason = :not_found
    end

    !not_found
  end
end
