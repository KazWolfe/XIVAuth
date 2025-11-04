class Admin::UsersController < Admin::AdminController
  include Pagy::Method

  before_action :set_user, except: %i[index]
  layout "portal/base"

  def index
    @pagy, @users = pagy(User.order(created_at: :desc))
  end

  def show
    @pagy_cregs, @cregs = pagy(@user.character_registrations, page_key: "page_cr", items: 10)
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    else
      redirect_to admin_user_path(@user), alert: "User could not be deleted."
    end
  end

  def destroy_mfa
    @user.webauthn_credentials.clear
    @user.totp_credential = nil

    if @user.save
      flash[:notice] = "MFA was removed for user."
    else
      flash[:error] = "MFA could not be removed for user."
    end

    redirect_back_or_to admin_user_path(@user)
  end

  def send_password_reset
    if @user.send_reset_password_instructions
      flash[:notice] = "A password reset email was sent to #{@user.email}."
    else
      flash[:error] = "Could not dispatch a password reset email."
    end

    redirect_back_or_to admin_user_path(@user)
  end

  def confirm
    if @user.confirm
      flash[:notice] = "The user was successfully confirmed."
    else
      flash[:error] = "Could not confirm user."
    end

    redirect_back_or_to admin_user_path(@user)
  end

  private def set_user
    @user = User.find(params[:id])
  end
end
