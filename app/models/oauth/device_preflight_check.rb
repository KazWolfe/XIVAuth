class OAuth::DevicePreflightCheck
  include ActiveModel::API

  attr_accessor :device_grant
  private :device_grant=

  attr_accessor :user
  private :user=

  private attr_accessor :user_errors
  private attr_accessor :app_errors

  validates :device_grant, presence: true

  validate :validate_user_has_characters
  validate :validate_incompatible_scopes

  def initialize(device_grant, user, attributes = { })
    self.device_grant = device_grant
    self.user = user
    super(attributes)
  end


  def oauth_client
    device_grant.application
  end

  def client_application
    oauth_client.application
  end

  delegate :scopes, to: :device_grant

  def validate_user_has_characters
    # Preflight will fail on request without this...
    return if device_grant.resource_owner.blank?

    return unless device_grant.resource_owner.respond_to?(:character_registrations)

    return unless device_grant.scopes.include?("character") || device_grant.scopes == ["character:all"]
    return unless device_grant.resource_owner.character_registrations.verified.empty?

    errors.add(:user_errors, :no_characters)
  end

  def validate_incompatible_scopes
    return unless scopes.include?("character") && scopes.include?("character:all")

    errors.add(:app_errors, :incompatible_scopes, message: "cannot use both character and character:all scopes")
  end
end
