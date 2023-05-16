# frozen_string_literal: true

class Users::TotpCredentialsController < ApplicationController
  def new
    if current_user.totp_credential&.otp_enabled
      return
    end

    @totp_credential = Users::TotpCredential.new(
      user_id: current_user.id,
      otp_secret: Users::TotpCredential.generate_otp_secret
    )

    session[:staged_totp_secret] = @totp_credential.otp_secret
  end

  def create
    @totp_credential = Users::TotpCredential.new(
      user_id: current_user.id,
      otp_secret: session[:staged_totp_secret],
      otp_enabled: true
    )

    @backup_codes = @totp_credential.generate_otp_backup_codes!

    render_new_form_again and return unless @totp_credential.valid?

    # Also will save here!
    unless @totp_credential.validate_and_consume_otp!(filtered_params[:otp_attempt])
      @totp_credential.errors.add(:otp_attempt, 'was invalid')
      render_new_form_again
    end
  end

  def destroy

  end

  private

  def render_new_form_again(status: :unprocessable_entity)
    render status: status,
           turbo_stream: turbo_stream.update('remote_modal-content', partial: 'users/totp_credentials/new_modal')
  end

  def filtered_params
    params.require(:users_totp_credential).permit(:otp_attempt)
  end
end
