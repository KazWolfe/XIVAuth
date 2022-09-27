class OAuth::DeviceAuthorizationsController < Doorkeeper::DeviceAuthorizationGrant::DeviceAuthorizationsController
  def index
    def index
      respond_to do |format|
        format.html
        format.json { head :no_content }
      end
    end
  end

  def create
    @device_grant = get_grant
    return unless @device_grant.present?

    pf = preflight_checks
    return pf if pf.present?

    redirect_to oauth_device_path(@device_grant)
  end

  def show
    @device_grant = get_grant
    return unless @device_grant.present?

    pf = preflight_checks
    return pf if pf.present?

    respond_to do |format|
      format.html
      format.json { render json: @device_grant.as_json }
    end
  end

  def update
    (destroy and return) if params[:disposition] == 'deny'

    @device_grant = get_grant
    return unless @device_grant.present?

    authorize
  end

  def destroy
    @device_grant = get_grant
    return unless @device_grant.present?

    @device_grant.denied = true
    @device_grant.save!

    respond_to do |format|
      format.html { redirect_to oauth_device_index_path, status: :see_other,
                                notice: "The request for code #{@device_grant.user_code} was successfully denied." }
      format.json { render json: { }, status: :no_content }
    end
  end

  def authorize
    # preflight checks
    pf = preflight_checks
    return pf if pf.present?

    device_grant_model.transaction do
      device_grant = device_grant_model.lock.find_by(user_code: user_code)
      device_grant.update!(user_code: nil, resource_owner_id: current_resource_owner.id)
    end

    authorization_success_response
  end

  private

  def get_grant
    code = params[:user_code].upcase
    grant = device_grant_model.lock.find_by(user_code: code)

    unless grant.present?
      error = "The code #{code} was not valid. Please check your code and try again."
      respond_to do |format|
        format.html { redirect_to oauth_device_index_path, status: :see_other, alert: error }
        format.json { render json: { errors: [error] }, status: :not_found }
      end
      return
    end

    grant
  end

  def authorization_error_response(error_message_key)
    respond_to do |format|
      notice = I18n.t(error_message_key, scope: i18n_flash_scope(:authorize))
      format.html { redirect_to oauth_device_index_url, alert: notice }
      format.json do
        render json: { errors: [notice] }, status: :unprocessable_entity
      end
    end
  end

  def authorization_success_response
    respond_to do |format|
      notice = I18n.t(:success, scope: i18n_flash_scope(:authorize))
      format.html { redirect_to oauth_device_index_url, notice: notice }
      format.json { head :no_content }
    end
  end

  def preflight_checks
    # preflight checks
    return authorization_error_response(:invalid_user_code) if @device_grant.nil?
    return authorization_error_response(:expired_user_code) if @device_grant.expired?
    return authorization_error_response(:denied_user_code) if @device_grant.denied

    return nil
  end
end
