# frozen_string_literal: true

class Admin::UsersController < Admin::AdminController
  include Pagy::Backend

  before_action :set_user, only: %i[show update destroy]

  def index
    @pagy, @users = pagy(User.order(created_at: :desc))
  end

  def show;
    @pagy_cregs, @cregs = pagy(@user.character_registrations, page_param: :page_cr, items: 10)
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: 'User deleted.'
    else
      redirect_to admin_user_path(@user), alert: 'User could not be deleted.'
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

end
