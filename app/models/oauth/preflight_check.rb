class OAuth::PreflightCheck
  include ActiveModel::API

  attr_accessor :pre_authorization
  private :pre_authorization=

  private attr_accessor :user_errors
  private attr_accessor :app_errors

  validates :pre_authorization, presence: true

  validate :validate_user_has_characters
  validate :validate_incompatible_scopes

  def initialize(pre_authorization, attributes = {})
    self.pre_authorization = pre_authorization
    super(attributes)
  end

  # helpers
  def user
    pre_authorization.resource_owner
  end

  def oauth_client
    pre_authorization.client.application
  end

  def client_application
    oauth_client.application
  end

  delegate :scopes, to: :pre_authorization

  def validate_user_has_characters
    return if pre_authorization.resource_owner.blank?
    return unless pre_authorization.resource_owner.respond_to?(:character_registrations)

    return unless pre_authorization.scopes.include?("character") || pre_authorization.scopes == ["character:all"]
    return unless pre_authorization.resource_owner.character_registrations.verified.empty?

    errors.add(:user_errors, :no_characters)
  end

  def validate_incompatible_scopes
    invalid_scopes = OAuth::GrantValidators::IncompatibleScopes.find_incompatible_scopes(scopes)

    invalid_scopes.each do |problem|
      errors.add(:app_errors, :incompatible_scopes,
                 message: "cannot request the following scopes together: #{problem.join(', ')}")
    end
  end
end
