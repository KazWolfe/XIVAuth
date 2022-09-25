class Api::UserController < ApiController
  before_action -> { doorkeeper_authorize! :user }

  def index
    @user = current_user
    respond_with build_user_obj(@user)
  end

  def build_user_obj(user)
    resp = {
      id: user.id,
      username: user.username
    }

    if doorkeeper_token.scopes.include?('user:email')
      resp[:email] = user.email
      resp[:email_verified] = user.confirmed_at.present?
    end

    resp[:verified_character_count] = user.characters.verified.count

    resp
  end
end
