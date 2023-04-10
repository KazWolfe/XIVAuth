class Api::V1::UserController < Api::V1::ApiController
  before_action :doorkeeper_authorize!
  respond_to :json

  def index
    @doorkeeper_token = doorkeeper_token
    @user = doorkeeper_token.resource_owner
  end
end
