class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :is_admin?
  
  def is_admin?
    redirect_to root_path unless current_user.admin?
  end
end
