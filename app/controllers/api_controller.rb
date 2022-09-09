class ApiController < ActionController::API
  include ActionController::MimeResponds

  # Universal Doorkeeper auth here; there are no "open" API endpoints
  before_action :doorkeeper_authorize!

  respond_to :json, :xml

  def current_user
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end
end
