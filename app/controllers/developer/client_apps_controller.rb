module Developer

  class ClientAppsController < ApplicationController
    before_action :set_application, only: %i[show edit update destroy regenerate]
    include Pagy::Backend

    helper Doorkeeper::DashboardHelper

    def index
      @pagy, @applications = pagy(OAuth::ClientApplication.accessible_by(current_ability).ordered_by(:created_at), items: 24)

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

            render json: { errors: }, status: :unprocessable_entity
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

            render json: { errors: }, status: :unprocessable_entity
          end
        end
      end
    end

    def regenerate
      authorize! :edit, @application

      @application.renew_secret

      if @application.save
        flash[:application_secret] = @application.plaintext_secret

        respond_to do |format|
          format.html { redirect_to developer_application_path(@application), notice: "Secret regenerated!" }
          format.json { render json: @application, as_owner: true }
        end
      else
        respond_to do |format|
          format.html do
            redirect_to developer_application_path(@application),
                        status: :unprocessable_entity,
                        error: "Could not regenerate app secret."
          end
          format.json { render json: @application, as_owner: true }
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
      @application = OAuth::ClientApplication.find(params[:id])
      authorize! :show, @application
    end

    private def application_params
      params.require(:doorkeeper_application)
            .permit(:name, :redirect_uri, { scopes: [] }, :confidential, :public)
    end

    private def i18n_scope(action)
      %i[doorkeeper flash applications] << action
    end
  end
end
