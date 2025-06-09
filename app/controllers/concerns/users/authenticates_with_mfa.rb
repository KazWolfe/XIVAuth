module Users::AuthenticatesWithMFA
  extend ActiveSupport::Concern

  def authenticate_with_mfa
    if mfa_params[:otp_attempt].present? && session.dig("mfa")
      authenticate_with_totp
    elsif mfa_params[:webauthn_response].present? && session.dig("mfa")
      authenticate_with_webauthn
    end
  end

  def prompt_for_mfa(status_code: :ok)
    session["mfa"] = {
      user_id: @user.id,
    }

    # webauthn
    if (@webauthn_challenge = Users::Webauthn::AuthenticateService.build_challenge_for_user(@user))
      session["mfa"]["webauthn_challenge"] = @webauthn_challenge.challenge
    end

    render "devise/sessions/mfa", status: status_code
  end

  private def reset_mfa_attempt!
    session.delete("mfa")
  end

  private def authenticate_with_webauthn
    challenge_data = session.dig("mfa", "webauthn_challenge")
    verifier = Users::Webauthn::AuthenticateService.new(@user, mfa_params[:webauthn_response], challenge_data)

    verifier.execute
    handle_mfa_success
  rescue WebAuthn::Error => e
    handle_mfa_failure("WebAuthn", message: e.message)
  end

  private def authenticate_with_totp
    unless @user.totp_credential&.otp_enabled
      handle_mfa_failure("TOTP", message: "TOTP is not configured!")
      return
    end

    if @user.totp_credential.validate_and_consume_otp_or_backup!(mfa_params[:otp_attempt])
      handle_mfa_success
    else
      handle_mfa_failure("TOTP", message: "TOTP was invalid or could not be verified.")
    end
  end

  private def handle_mfa_success
    reset_mfa_attempt!

    sign_in(:user, @user)
  end

  private def handle_mfa_failure(method, message: nil)
    flash.now[:alert] = "MFA authentication via #{method} failed: #{message}"
    prompt_for_mfa(status_code: :unprocessable_entity)
  end

  def mfa_params
    params.permit(mfa: [:otp_attempt, :webauthn_response]).fetch(:mfa, {})
  end
end
