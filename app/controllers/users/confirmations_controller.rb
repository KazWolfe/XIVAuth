class Users::ConfirmationsController < ApplicationController
  helper Users::SessionsHelper
  layout "login/signin"

  skip_before_action :authenticate_user!

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    @user = User.confirm_by_token(params[:confirmation_token])

    if @user.errors.empty?
      flash[:notice] = "Your account has been confirmed. Welcome to XIVAuth!"
      redirect_to stored_location_for(@user) || character_registrations_path
    else
      redirect_to user_recovery_path, alert: @user.errors.full_messages.join("\n")
    end
  end
end
