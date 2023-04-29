# frozen_string_literal: true

# MFA logic from https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/sessions_controller.rb

class Users::SessionsController < Devise::SessionsController
  include Auth::AuthenticatesWithMFA

  prepend_before_action :check_captcha, only: [:create]
  prepend_before_action :authenticate_with_mfa, if: -> { action_name == 'create' && mfa_enabled? }
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super
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
  
  private

  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new sign_in_params

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error)
      render :new
    end
  end

  def mfa_enabled?
    # ToDo: Implementation
    return true
    
    find_user&.requires_mfa?
  end

  def find_user
    return @s_user if defined?(@s_user)

    if session[:mfa_user_id] && user_params[:email]
      @s_user = User.find_by_email(user_params[:email]).find_by_id(session[:mfa_user_id])
    elsif session[:mfa_user_id]
      @s_user = User.find(session[:mfa_user_id])
    elsif user_params[:email]
      @s_user = User.find_by_email(user_params[:email])
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :otp_attempt, :device_response)
  end
end
