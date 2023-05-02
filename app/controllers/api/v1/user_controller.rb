class Api::V1::UserController < Api::V1::ApiController
  before_action -> { doorkeeper_authorize! :user }

  def index
    @user = doorkeeper_token.resource_owner
  end
end
