module Developer

  class ClientAppsController < ApplicationController
    before_action :set_application, only: %i[show edit update destroy regenerate]
    include Pagy::Backend
    helper Doorkeeper::DashboardHelper
    
    def index
      @pagy, @applications = pagy(ClientApplication.accessible_by(current_ability), items: 24)

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
      @application = ClientApplication.new
    end

    def create
      @application = ClientApplication.new(application_params)
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

            render json: { errors: }, status: :unprocessable_entity
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

    private def set_application
      @application = ClientApplication.find(params[:id])

      # specifically show RecordNotFound if we can't see it, rather than 403.
      raise ActiveRecord::RecordNotFound unless can? :show, @application
    end
  end
end
