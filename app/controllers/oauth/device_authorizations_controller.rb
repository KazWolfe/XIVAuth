require 'utilities/crockford'

class OAuth::DeviceAuthorizationsController < ::Doorkeeper::DeviceAuthorizationGrant::DeviceAuthorizationsController
  def index
    # User code is present, shunt over and try to authorize.
    if user_code.present?
      if device_grant.present? && !device_grant.expired?
        new
        return
      elsif device_grant.present? && device_grant.expired?
        device_grant.errors.add(:user_code, :expired, message: "has expired.")
      elsif device_grant.nil?
        @device_grant = device_grant_model.new(user_code: user_code)
        @device_grant.errors.add(:user_code, :invalid, message: "was not found")
      end
    else
      @device_grant = device_grant_model.new
    end

    respond_to do |format|
      format.html
      format.json { head :no_content }
    end
  end

  def new
    device_grant.validate
    @preflight = ::OAuth::DevicePreflightCheck.new(device_grant, current_resource_owner)

    unless @preflight.valid?
      render_preflight_error
      return
    end

    render "oauth/device_authorizations/new", locals: { model: device_grant }
  end

  def authorize
    if params["disposition"] == "find"
      redirect_to oauth_device_authorizations_index_path(user_code: user_code)
      return
    end

    (destroy and return) if params["disposition"] == "deny"

    device_grant_model.transaction do
      device_grant = device_grant_model.lock.find_by(user_code: user_code)
      next authorization_error_response(:invalid_user_code) if device_grant.nil?
      next authorization_error_response(:expired_user_code) if device_grant.expired?

      device_grant.update!(user_code: nil, resource_owner_id: current_resource_owner.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("oauth-consent-ui", partial: "oauth/device_authorizations/success", locals: { model: device_grant })
        end
        format.html { render :create, locals: { model: device_grant }, status: :created }
        format.json { head :no_content }
      end
    end
  end

  def destroy
    device_grant.expires_in = 0

    if device_grant.save
      redirect_to oauth_device_authorizations_index_path, notice: "Device authorization revoked."
    else
      redirect_to oauth_device_authorizations_index_path, alert: "Device authorization could not be revoked."
    end
  end

  private def device_grant
    normalized = Crockford.normalize(user_code)
    @device_grant ||= device_grant_model.find_by(user_code: normalized)
  end

  private def render_preflight_error
    render "doorkeeper/authorizations/preflight_error", status: :bad_request
  end
end