class OAuth::DeviceAuthorizationsController < ::Doorkeeper::DeviceAuthorizationGrant::DeviceAuthorizationsController
  def index
    respond_to do |format|
      format.html
      format.json { head :no_content }
    end
  end
end