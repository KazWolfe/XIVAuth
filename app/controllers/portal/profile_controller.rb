class Portal::ProfileController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
  end

  def update
    @user = current_user
  end
end
