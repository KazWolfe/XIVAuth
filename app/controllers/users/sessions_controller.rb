class Users::SessionsController < Devise::SessionsController
  include Users::AuthenticatesWithMFA

  prepend_before_action :authenticate_with_mfa, if: -> { action_name == "create" && mfa_required? }
  prepend_before_action :check_captcha, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super do |resource|
      # If a user has signed in, they no longer need to reset their password.
      if resource.reset_password_token.present?
        resource.update(reset_password_token: nil, reset_password_sent_at: nil)
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  def check_captcha
    # Ignore for non-credential submissions
    return unless user_params[:password].present?

    return if verify_recaptcha

    self.resource = resource_class.new sign_in_params

    flash.discard(:recaptcha_error)
    render :new, status: :unprocessable_entity
  end

  def mfa_required?
    find_user&.requires_mfa?
  end

  def find_user
    if session[:otp_user_id] && user_params[:email]
      User.where(email: user_params[:email]).find_by_id(session[:otp_user_id])
    elsif session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by_email(user_params[:email])
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :otp_attempt, :device_response, :remember_me)
  end
end
