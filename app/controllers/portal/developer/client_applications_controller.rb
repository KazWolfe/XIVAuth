class Portal::Developer::ClientApplicationsController < ApplicationController
  before_action :authenticate_user!
  respond_to :html, :json

  def index
    # @applications = OAuth::ClientApplication.accessible_by(current_ability)
    @applications = current_user.oauth_client_applications.order(:created_at)

    respond_with @applications
  end

  def show
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :show, @application

    respond_with @application
  end

  def new
    @application = OAuth::ClientApplication.new
  end

  def create
    # Only allow *ONE* scope from the approved list on creation
    unless %w[character user].include? sanitized_params[:scopes].to_s
      Rails.logger.warn('Attempt to create an application with extra scopes blocked')
      respond_to do |format|
        format.html { render :new, status: :forbidden }
        format.json { render json: { error: 'Not authorized to use requested scope' }, status: :forbidden }
      end

      return
    end

    @application = OAuth::ClientApplication.new(sanitized_params)
    @application.owner = current_user

    if @application.save!
      flash[:application_secret] = @application.plaintext_secret
      respond_to do |format|
        format.html { redirect_to developer_application_path(@application) }
        format.json { render json: @application.to_json, status: :created}
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @application.errors, status: :unprocessable_entity }
      end
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

    if @application.save
      respond_to do |format|
        format.html { redirect_to developer_application_path(@application) }
        format.json { render json: @application.as_json, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render status: :unprocessable_entity }
        format.json { render json: @application.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :destroy, @application

    if @application.destroy
      respond_to do |format|
        format.html { redirect_to developer_applications_path, status: :see_other }
        format.json { render status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :show, error: @application.errors }
        format.json { render json: @application.errors, status: :bad_request }
      end
    end
  end

  protected

  def regenerate_secret(application)
    application.renew_secret

    application.save!
    flash[:application_secret] = application.plaintext_secret
  end

  def sanitized_params(allow_scopes: true)
    permitted_fields = %i[name redirect_uri icon_url]
    permitted_fields << :scopes if allow_scopes

    params.require(:oauth_client_application).permit(permitted_fields)
  end
end
