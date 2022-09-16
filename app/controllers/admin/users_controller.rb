class Admin::UsersController < AdminController
  def index
    @users = User.accessible_by(current_ability)
  end

  def show
    @user = User.find(params[:id])
  end

  def anonymize
    # todo: figure out how to anonymize and block a user from doing things
  end

  def update
    @user = User.find(params[:id])

    if params['confirm_now']
      @user.skip_confirmation!
    end

    if params['reset_password']
      @user.password = Devise.friendly_token(36)

      # todo: generate and send password reset email
    end

    if params['reset_mfa']
      # todo: reset user's mfa
    end

    sanitized_params = params.require(:user).permit(:username, :roles, :email_address)

    @user.update(params[:user])
    @user.save!
  end

  def destroy
    @user = User.find(params[:id])

    # block deletion of users that own apps
    if @user.oauth_client_applications.count > 0
      render status: 400 and return
    end

    @user.destroy!
  end
end
