class Portal::Developer::ClientApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @applications = Oauth::ClientApplication.accessible_by(current_ability)
    
    @applications
  end

  def show
    @application = Oauth::ClientApplication.find(params[:id])
    authorize! :show, @application
    
    @application
  end

  def new
    @application = Oauth::ClientApplication.new
  end

  def create
    @application = Oauth::ClientApplication.new(application_params)
    @application.owner = current_user

    if @application.save
      redirect_to oauth_application_url(@application)
    else
      render :new
    end
  end

  def update
    @application = Oauth::ClientApplication.find(params[:id])
    authorize! :update, @character
  end

  def destroy
    @application = Oauth::ClientApplication.find(params[:id])
    authorize! :destroy, @character
  end

  protected
  def sanitized_params
    params.require(:client_application)
          .permit(:name, :redirect_uri, :scopes, :confidential, :icon_url)
  end
end
