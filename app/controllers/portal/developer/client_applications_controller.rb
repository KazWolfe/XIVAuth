class Portal::Developer::ClientApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # @applications = OAuth::ClientApplication.accessible_by(current_ability)
    @applications = current_user.oauth_client_applications.order(:created_at)
  end

  def show
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :show, @application
  end

  def new
    @application = OAuth::ClientApplication.new
  end

  def create
    # Only allow our permitted micro-scopes at app creation.
    unless %w[character user].include? sanitized_params[:scopes].to_s
      Rails.logger.warn('Attempt to create an application with extra scopes blocked')
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
    authorize! :update, @application

    if params[:command] == 'regenerate'
      regenerate_secret(@application)
      redirect_to developer_application_path(@application) and return
    end

    @application.update(sanitized_params(allow_scopes: false))

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

  def regenerate_secret(application)
    application.renew_secret

    application.save!
    flash[:application_secret] = application.plaintext_secret
  end

  def sanitized_params(allow_scopes: true)
    permitted_fields = [:name, :redirect_uri, :icon_url]
    permitted_fields << :scopes if allow_scopes

    params.require(:oauth_client_application)
          .permit(permitted_fields)
  end
end
