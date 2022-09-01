class Admin::UsersController < AdminController
  def index
    @users = User.accessible_by(current_ability)
  end

  def show
    @user = User.find(params[:id])
  end
end
