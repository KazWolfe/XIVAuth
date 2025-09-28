module Developer

  class ClientAppsController < ApplicationController
    layout "portal/page"
    include Pagy::Backend
    helper Doorkeeper::DashboardHelper

    before_action :set_application, only: %i[show edit update destroy regenerate]
    
    def index
      @pagy, @applications = pagy(accessible_applications, items: 24)

      respond_to do |format|
        format.html { render :index, layout: "portal/base" }
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
      @application = ClientApplication.new
    end

    def create
      @application = ClientApplication.new(application_params)
      @application.owner = current_user

      if @application.save
        flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications create])

        respond_to do |format|
          format.html { redirect_to developer_application_path(@application) }
          format.json { render json: @application, as_owner: true }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json do
            errors = @application.errors.full_messages

            render json: { errors: }, status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      authorize! :destroy, @application

      flash[:notice] = "Application destroyed." if @application.destroy

      respond_to do |format|
        format.html { redirect_to developer_applications_url }
        format.json { head :no_content }
      end
    end

    def update
      authorize! :update, @application

      if @application.update(application_params)
        flash[:notice] = "Application updated successfully"

        respond_to do |format|
          format.html { redirect_to developer_application_path(@application) }
          format.json { render json: @application, as_owner: true }
        end
      else
        respond_to do |format|
          format.html { render :edit }
          format.json do
            errors = @application.errors.full_messages

            render json: { errors: errors }, status: :unprocessable_entity
          end
        end
      end
    end

    private def accessible_applications
      ClientApplication.where(owner: current_user).or(ClientApplication.where(owner: current_user.associated_teams))
    end

    private def set_application
      @application = ClientApplication.find(params[:id])

      # specifically show RecordNotFound if we can't see it, rather than 403.
      raise ActiveRecord::RecordNotFound unless can? :show, @application
    end

    private def application_params
      params.require(:client_application)
            .permit(:name, :private)
    end
  end
end
