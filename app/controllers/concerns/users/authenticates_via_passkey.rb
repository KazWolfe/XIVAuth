module Users::AuthenticatesViaPasskey
  extend ActiveSupport::Concern

  def generate_discoverable_challenge
    @discoverable_challenge = Users::Webauthn::AuthenticateService.build_discoverable_challenge
    session["webauthn_discoverable_challenge"] = @discoverable_challenge.challenge
  end

  def authenticate_via_passkey(response_data)
    challenge_data = session["webauthn_discoverable_challenge"]
    verifier = Users::Webauthn::AuthenticateService.new(@user, response_data, challenge_data)

    # see CVE-2020-8236 for why we need UV.
    verifier.execute(user_verification: true)

    sign_in(:user, @user)
  rescue WebAuthn::Error => e
    flash.now[:alert] = "Passkey authentication failed: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def reset_passkey_challenge!
    session.delete("webauthn_discoverable_challenge")
  end
end