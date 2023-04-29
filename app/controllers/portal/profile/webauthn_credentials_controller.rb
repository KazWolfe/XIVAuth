class Portal::Profile::WebauthnCredentialsController < ApplicationController
  # Borrowing heavily from https://github.com/CiTroNaK/webauthn-with-devise and
  # https://www.honeybadger.io/blog/multi-factor-2fa-authentication-rails-webauthn-devise/

  def create
    webauthn_credential = WebAuthn::Credential.from_create(params[:credential])

    begin
      webauthn_credential.verify(session[:webauthn_credential_register_challenge])

      credential = current_user.webauthn_credentials.new(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        nickname: params[:nickname],
        sign_count: webauthn_credential.sign_count
      )

      if credential.save
        redirect_to profile_path, status: :see_other
      else
        # Handle save error
      end
    rescue WebAuthn::Error => e
      # Handle error on verification
    ensure
      session.delete(:webauthn_credential_register_challenge)
    end
  end

  def destroy
    credential = current_user.webauthn_credentials.find(params[:id])
    credential.destroy!

    redirect_to profile_path, status: :see_other
  end

  def challenge
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.id,
        display_name: current_user.username,
        name: current_user.username
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id)
    )

    session[:webauthn_credential_register_challenge] = create_options.challenge

    respond_to do |format|
      format.json { render json: create_options }
    end
  end
end
