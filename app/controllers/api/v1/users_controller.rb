class Api::V1::UsersController < Api::V1::ApiController
  before_action -> { doorkeeper_authorize! :user }
  before_action :check_resource_owner_presence

  before_action only: %i[jwt] do
    doorkeeper_authorize! 'user:jwt', 'user:manage'
  end

  def show
    @user = current_user
  end

  def jwt
    @user = current_user
  end
end
