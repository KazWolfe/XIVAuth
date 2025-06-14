module Users::AuthenticatesWithMFA
  extend ActiveSupport::Concern

  # From https://cheeger.com/developer/2018/09/17/enable-two-factor-authentication-for-rails.html
  included do
    # This action comes from DeviseController, but because we call `sign_in`
    # manually, not skipping this action would cause a "You are already signed
    # in." error message to be shown upon successful login.
    skip_before_action :require_no_authentication, only: [:create], raise: false
  end

  def authenticate_with_mfa
    if mfa_params[:otp_attempt].present? && session.dig("mfa")
      authenticate_with_totp(@user)
    elsif mfa_params[:webauthn_response].present? && session.dig("mfa")
      authenticate_with_webauthn(@user)
    end
  end

  def prompt_for_mfa(user, status_code: :ok)
    session["mfa"] = {
      otp_user_id: user.id,
    }

    # webauthn
    @webauthn_challenge = Users::Webauthn::AuthenticateService.build_challenge_for_user(user)
    session["mfa"]["webauthn_challenge"] = @webauthn_challenge&.challenge

    render "devise/sessions/mfa", status: status_code
  end

  private def reset_mfa_attempt!
    session.delete("mfa")
  end

  private def authenticate_with_webauthn(user)
    Users::Webauthn::AuthenticateService.new(user, mfa_params[:webauthn_response], session.dig("mfa", "webauthn_challenge")).execute
    handle_mfa_success(user)
  rescue WebAuthn::Error => e
    handle_mfa_failure(user, "WebAuthn", message: e.message)
  end

  private def authenticate_with_totp(user)
    unless user.totp_credential&.otp_enabled
      handle_mfa_failure(user, "TOTP", message: "TOTP is not configured!")
      return
    end

    if user.totp_credential.validate_and_consume_otp_or_backup!(mfa_params[:otp_attempt])
      handle_mfa_success(user)
    else
      handle_mfa_failure(user, "TOTP", message: "TOTP was invalid or could not be verified.")
    end
  end

  private def handle_mfa_success(user)
    reset_mfa_attempt!

    sign_in(:user, user)
  end

  private def handle_mfa_failure(user, method, message: nil)
    flash.now[:alert] = "MFA authentication via #{method} failed: #{message}"
    prompt_for_mfa(user, status_code: :unprocessable_entity)
  end

  def mfa_params
    params.permit(mfa: [:otp_attempt, :webauthn_response]).fetch(:mfa, {})
  end
end
