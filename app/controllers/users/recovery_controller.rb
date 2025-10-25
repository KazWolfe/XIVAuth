class Users::RecoveryController < ApplicationController
  helper Users::SessionsHelper
  layout "login/signin"

  skip_before_action :authenticate_user!
  prepend_before_action :check_captcha, only: [:create]

  def new
    @user = User.new
    render 'devise/recovery/new'
  end

  def create
    if permitted_params[:email].blank?
      @user = User.new
      @user.errors.add(:email, "can't be blank")

      render "devise/recovery/new", status: :unprocessable_entity
      return
    end

    @user = User.find_by(email: permitted_params[:email])

    if @user.nil?
      redirect_to new_user_session_path, notice: "Your recovery request was received. If your email is in our " +
        "system, you should receive a recovery email shortly."
      return
    end

    if !@user.confirmed?
      @user.resend_confirmation_instructions
    else
      @user.send_reset_password_instructions
    end

    redirect_to new_user_session_path, notice: "Your recovery request was received. If your email is in our system, " +
      "you should receive a recovery email shortly."
  rescue Postmark::InactiveRecipientError
    flash.now[:error] = render_to_string(partial: "devise/mailer/mta_error")
    render "devise/recovery/new", status: :unprocessable_entity
  end

  def permitted_params
    params.require(:user).permit(:email)
  end

  private def check_captcha
    return if cloudflare_turnstile_ok?

    flash.now[:alert] = "CAPTCHA verification failed. Please try again."
    @user = User.new
    render 'devise/recovery/new', status: :unprocessable_content
  end
end