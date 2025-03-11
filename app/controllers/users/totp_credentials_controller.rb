class Users::TotpCredentialsController < ApplicationController
  def new
    if current_user.totp_credential&.otp_enabled
      return
    end

    @totp_credential = User::TotpCredential.new(
      user_id: current_user.id,
      otp_secret: User::TotpCredential.generate_otp_secret
    )

    session[:staged_totp_secret] = @totp_credential.otp_secret
  end

  def create
    return if current_user.totp_credential&.otp_enabled

    @totp_credential = User::TotpCredential.new(
      user_id: current_user.id,
      otp_secret: session[:staged_totp_secret],
      otp_enabled: true
    )

    @backup_codes = @totp_credential.generate_otp_backup_codes!

    render_new_form_again and return unless @totp_credential.valid?

    # Also will save here!
    unless @totp_credential.validate_and_consume_otp!(filtered_params[:otp_attempt])
      @totp_credential.errors.add(:otp_attempt, "was invalid")
      render_new_form_again
    end
  end

  def destroy
    @totp_credential = current_user.totp_credential

    otp_attempt = params.dig(:users_totp_credential, :otp_attempt)

    # If TOTP code isn't present, the user just clicked on the button.
    render and return if otp_attempt.nil?

    unless @totp_credential.validate_and_consume_otp_or_backup!(otp_attempt)
      @totp_credential.errors.add(:otp_attempt, "was invalid")
      render status: :unprocessable_entity,
             turbo_stream: turbo_stream.update("remote_modal-content", partial: "users/totp_credentials/destroy_modal")

      return
    end

    if @totp_credential.delete
      flash[:notice] = "TOTP credential successfully removed."
    else
      flash[:error] = "TOTP credential could not be removed."
    end

    redirect_to edit_user_registration_path
  end

  private def render_new_form_again(status: :unprocessable_entity)
    render status: status,
           turbo_stream: turbo_stream.update("remote_modal-content", partial: "users/totp_credentials/new_modal")
  end

  private def filtered_params
    params.require(:users_totp_credential).permit(:otp_attempt)
  end
end
