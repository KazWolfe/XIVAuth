class Api::UserController < ApiController
  before_action -> { doorkeeper_authorize! :user }

  def index
    @user = current_user
    respond_with build_user_obj(@user)
  end

  def build_user_obj(user)
    if doorkeeper_token[:scopes].include?('user:email')
      resp = {
        id: user.id,
        username: user.username,
        email: user.email,
        email_verified: user.confirmed_at.present?,
      }
    else
      resp = {
        id: user.pairwise_id(doorkeeper_token[:application_id]),
        username: user.username,  # usernames are non-unique so no guarantee applies
      }
    end

    resp[:verified_characters] = user.characters.verified.count

    resp
  end
end
