class Api::UserController < ApiController
  before_action -> { doorkeeper_authorize! :user }

  def index
    @user = current_user
    respond_with build_user_obj(@user)
  end

  def build_user_obj(user)
    resp = {
      id: user.pairwise_id(doorkeeper_token.application.pairwise_key),
      username: user.username      # usernames are not trackable information? mmmm...
    }

    if doorkeeper_token.scopes.include?('user:email')
      resp[:persistent_id] = user.id
      resp[:email] = user.email
      resp[:email_verified] = user.confirmed_at.present?
    end

    resp[:verified_character_count] = user.characters.verified.count

    resp
  end
end
