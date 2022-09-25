class OAuth::DeviceCodesController < Doorkeeper::DeviceAuthorizationGrant::DeviceCodesController
  def create
    super
  rescue Doorkeeper::Errors::DoorkeeperError => e
    handle_token_exception(e)
  rescue ActiveRecord::RecordInvalid => ve
    # ?!?! - DeviceAuthorizationGrant needs to have things sorta hacked into existence to better handle errors.
    # Namely, scope validation errors don't really get caught properly and will 500. This shims around that a bit.
    # https://github.com/exop-group/doorkeeper-device_authorization_grant/issues/9
    handle_token_exception(ve.record.errors.first)
  end
end
