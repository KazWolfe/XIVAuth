class Users::PasswordsController < Devise::PasswordsController
  helper Users::SessionsHelper
  layout "login/signin"

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    super
  end

  # PUT /resource/password
  def update
    super
  end

  # protected

  def after_resetting_password_path_for(resource)
    user_session_path
  end

  protected def assert_reset_token_passed
    if params[:reset_password_token].blank?
      set_flash_message(:alert, :no_token)
      redirect_to new_user_session_path
    end
  end
end
