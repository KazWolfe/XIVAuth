class Api::V1::UsersController < Api::V1::ApiController
  before_action -> { doorkeeper_authorize! :user }
  before_action :check_resource_owner_presence

  before_action only: %i[jwt] do
    doorkeeper_authorize! 'user:jwt', 'user:manage'
  end

  def show
    @user = current_user
    @social_identities = authorized_social_identities if doorkeeper_token.scopes.exists?('user:social')
  end

  def jwt
    @user = current_user
  end
  
  private
  
  def authorized_social_identities
    result = []
    policy = @doorkeeper_token.permissible_policy
    
    @user.social_identities.each do |identity|
      next if policy.present? && !policy.can_access_resource?(identity)
      
      result << identity
    end
    
    result
  end
end
