class Portal::ProfileController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
  end

  def update
    @user = current_user
    filtered_params = params.require(:user).permit([:username], [:email])

    @user.update(filtered_params)
  end
  
  def destroy
    @user = current_user
    
    
  end
end
