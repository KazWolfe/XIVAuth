class OAuth::DeviceGrant < ActiveRecord::Base
  include Doorkeeper::DeviceAuthorizationGrant::DeviceGrantMixin
  include Doorkeeper::Models::Scopes

  def to_param
    user_code
  end

  self.table_name = 'oauth_device_grants'

  validate :validate_scopes_safe

  private

  def validate_scopes_safe
    # warn: duplicate code from the device authorization request monkeypatch
    scopes_valid = scopes.present? && Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(
      scope_str: scopes.to_s,
      server_scopes: Doorkeeper.config.scopes,
      app_scopes: application.scopes,
      grant_type: Doorkeeper::DeviceAuthorizationGrant::OAuth::DEVICE_CODE
    )

    errors.add(:scopes, :invalid_scope) unless scopes_valid
  end
end
