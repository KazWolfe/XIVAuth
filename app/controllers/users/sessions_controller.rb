class Users::SessionsController < Devise::SessionsController
  include Users::AuthenticatesWithMFA
  include Users::AuthenticatesViaPasskey

  layout "login/signin"

  prepend_before_action :reset_mfa_attempt!, only: [:new]
  prepend_before_action :generate_discoverable_challenge, only: [:new]

  prepend_before_action :evaluate_login_flow, only: [:create]
  prepend_before_action :check_captcha, only: [:create]

  # From https://cheeger.com/developer/2018/09/17/enable-two-factor-authentication-for-rails.html
  # This action comes from DeviseController, but because we call `sign_in`
  # manually, not skipping this action would cause a "You are already signed
  # in." error message to be shown upon successful login.
  skip_before_action :require_no_authentication, only: [:create], raise: false

  def create
    super do |resource|
      # If a user has signed in, they no longer need to reset their password.
      resource.update(reset_password_token: nil, reset_password_sent_at: nil) if resource.reset_password_token.present?

      # and clean up any stray session data
      reset_mfa_attempt!
      reset_passkey_challenge!
    end
  end

  def check_captcha
    # only check captcha if this is a first-level login attempt
    return unless user_params[:webauthn_response].present? || user_params[:password].present?
    return if cloudflare_turnstile_ok?

    self.flash.now[:alert] = "CAPTCHA verification failed. Please try again."
    self.resource = resource_class.new sign_in_params

    # recall all the new session things
    generate_discoverable_challenge
    render :new, status: :unprocessable_content 
  end

  def evaluate_login_flow
    if user_params[:webauthn_response].present?
      cred = WebAuthn::Credential.from_get(JSON.parse(user_params[:webauthn_response]))
      @user = User.find_by_webauthn_id(cred.user_handle)
      self.resource = @user

      if self.resource
        authenticate_via_passkey(user_params[:webauthn_response])
      else
        logger.warn("WebAuthn login attempt with an unknown user_handle.")
        self.flash.now[:alert] = "Security key presented is not registered."

        self.resource = resource_class.new
        render :new, status: :unprocessable_content 

        return
      end
    elsif user_params[:email].present?
      @user = User.find_by(email: user_params[:email])
      self.resource = @user

      if self.resource&.valid_password?(user_params[:password]) && self.resource&.mfa_enabled?
        reset_mfa_attempt!
        prompt_for_mfa(status_code: :unprocessable_content )
      else
        # implicit; use devise default flow (password only)
      end
    elsif session["mfa"]
      @user = User.find(session["mfa"]["user_id"])
      self.resource = @user

      authenticate_with_mfa
    end
  end

  def user_params
    params.permit(user: [:email, :password, :webauthn_response, :remember_me]).fetch(:user, {})
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || character_registrations_path
  end
end