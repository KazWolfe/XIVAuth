# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  helper Users::SessionsHelper

  before_action :configure_sign_up_params, only: [:create]
  prepend_before_action :check_captcha, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  
  before_action :check_registration_allowed, only: %i[new create]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    super
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    super
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  def update_resource(resource, params)
    # block updates of protected fields
    return super if params[:password].present? || params[:password_confirmation].present?
    return super if params[:email].present? && params[:email] != current_user.email

    # NOTE: we're filtering out allowable attributes early so this is safe-ish. may cause headaches later though.
    resource.update_without_password(params.slice(:profile_attributes))
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [profile_attributes: [:display_name]])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [profile_attributes: [:display_name]])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  def check_registration_allowed
    return if User.signup_permitted?

    sign_out current_user
    redirect_to new_user_session_path, alert: 'Sign-ups are disabled at this time.'
  end

  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new sign_up_params
    resource.validate
    set_minimum_password_length

    flash.discard(:recaptcha_error)
    render :new, status: :unprocessable_entity
  end
end
