class Users::SessionsController < Devise::SessionsController
  include Users::AuthenticatesWithMFA
  include Users::AuthenticatesViaPasskey

  prepend_before_action :reset_mfa_attempt!, only: [:new]
  prepend_before_action :generate_discoverable_challenge, only: [:new]

  prepend_before_action :evaluate_login_flow, only: [:create]
  prepend_before_action :check_captcha, only: [:create]

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

    return if verify_recaptcha

    self.resource = resource_class.new sign_in_params

    flash.discard(:recaptcha_error)
    render :new, status: :unprocessable_entity
  end

  def find_user
    if user_params[:email].present?
      User.find_by(email: user_params[:email])
    elsif user_params[:webauthn_response].present?
      cred = WebAuthn::Credential.from_get(JSON.parse(user_params[:webauthn_response]))
      User.find(cred.user_handle)
    elsif session.dig("mfa")
      User.find(session["mfa"]["otp_user_id"])
    else
      nil
    end
  end

  def evaluate_login_flow
    @user ||= find_user
    self.resource = @user

    if user_params[:webauthn_response].present?
      authenticate_via_passkey(@user, user_params[:webauthn_response])
    elsif self.resource&.valid_password?(user_params[:password]) && self.resource&.requires_mfa?
      reset_mfa_attempt!
      prompt_for_mfa(self.resource)
    elsif session["mfa"]
      authenticate_with_mfa
    else
      # implicit; use devise default flow (password only)
    end
  end

  def user_params
    params.permit(user: [:email, :password, :webauthn_response, :remember_me]).fetch(:user, {})
  end
end