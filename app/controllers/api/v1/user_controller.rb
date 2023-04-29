class Api::V1::UserController < Api::V1::ApiController
  def index
    @user = doorkeeper_token.resource_owner
  end
end
