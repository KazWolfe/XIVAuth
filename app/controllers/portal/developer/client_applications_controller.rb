class Portal::Developer::ClientApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @applications = OAuth::ClientApplication.accessible_by(current_ability)
    
    @applications
  end

  def show
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :show, @application
    
    @application
  end

  def new
    @application = OAuth::ClientApplication.new
  end

  def create
    # Only allow our permitted micro-scopes at app creation.
    unless %w[character user].include? sanitized_params[:scopes].to_s
      Rails.logger.warn("Attempt to create an application with extra scopes blocked")
      render :new, status: :forbidden and return
    end

    @application = OAuth::ClientApplication.new(sanitized_params)
    @application.owner = current_user

    if @application.save!
      flash[:application_secret] = @application.plaintext_secret
      redirect_to developer_application_path(@application)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :update, @character

    @application.update(sanitized_params)

    if @application.save!
      redirect_to developer_application_path(@application)
    else
      render status: :unprocessable_entity
    end
  end

  def destroy
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :destroy, @application

    if @application.verified?
      Rails.logger.warn('Attempted to delete a verified application!')
      render status: :forbidden and return
    end

    @application.destroy!

    redirect_to developer_applications_path, status: :see_other
  end

  protected

  def sanitized_params
    params.require(:oauth_client_application)
          .permit(:name, :redirect_uri, :scopes, :icon_url)
  end
end
