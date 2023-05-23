class Developer::ClientAppsController < ApplicationController
  before_action :set_application, only: %i[show edit update destroy]

  helper Doorkeeper::DashboardHelper

  def index
    @applications = OAuth::ClientApplication.accessible_by(current_ability).ordered_by(:created_at)

    respond_to do |format|
      format.html
      format.json { head :no_content }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @application, as_owner: true }
    end
  end

  def new
    @application = OAuth::ClientApplication.new
  end

  def create
    @application = OAuth::ClientApplication.new(application_params)
    @application.owner = current_user

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications create])
      flash[:application_secret] = @application.plaintext_secret

      respond_to do |format|
        format.html { redirect_to developer_application_path(@application) }
        format.json { render json: @application, as_owner: true }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          errors = @application.errors.full_messages

          render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    authorize! :edit, @application

    if @application.update(application_params)
      flash[:notice] = I18n.t(:notice, scope: i18n_scope(:update))

      respond_to do |format|
        format.html { redirect_to developer_application_path(@application) }
        format.json { render json: @application, as_owner: true }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          errors = @application.errors.full_messages

          render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    authorize! :destroy, @application

    flash[:notice] = I18n.t(:notice, scope: i18n_scope(:destroy)) if @application.destroy

    respond_to do |format|
      format.html { redirect_to developer_applications_url }
      format.json { head :no_content }
    end
  end

  private

  def set_application
    @application = OAuth::ClientApplication.find(params[:id])
    authorize! :show, @application
  end

  def application_params
    params.require(:doorkeeper_application)
          .permit(:name, :redirect_uri, { scopes: [] }, :confidential, :public)
  end

  def i18n_scope(action)
    %i[doorkeeper flash applications] << action
  end
end
