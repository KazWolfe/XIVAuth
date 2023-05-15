# frozen_string_literal: true

class Users::WebauthnCredentialsController < ApplicationController

  def new
    @webauthn_credential = Users::WebauthnCredential.new
    @challenge = build_challenge
  end

  def destroy
    credential = current_user.webauthn_credentials.find(params[:id])
    credential.destroy

    redirect_to edit_user_registration_path, notice: "Credential was removed."
  end

  def create
    recovered_credential = WebAuthn::Credential.from_create(JSON.parse create_params[:credential])

    begin
      recovered_credential.verify(session[:webauthn_register_challenge])

      @webauthn_credential = current_user.webauthn_credentials.new(
        external_id: recovered_credential.id,
        public_key: recovered_credential.public_key,
        nickname: create_params[:nickname],
        sign_count: recovered_credential.sign_count
      )

      if @webauthn_credential.save
        redirect_to edit_user_registration_path
      else
        respond_to do |format|
          format.turbo_stream { render :new, status: :unprocessable_entity }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    rescue WebAuthn::Error => e
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    ensure
      session.delete(:webauthn_register_challenge)
    end
  end

  private

  def create_params
    params.require(:users_webauthn_credential)
          .permit(:credential, :nickname)
  end

  def build_challenge
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.id,
        display_name: current_user.email,
        name: current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id)
    )

    session[:webauthn_register_challenge] = create_options.challenge

    create_options
  end
end
