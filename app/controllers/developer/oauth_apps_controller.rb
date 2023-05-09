class Developer::OAuthAppsController < Doorkeeper::ApplicationsController
  # A lot of the code in this class duplicates that of Doorkeeper's own ApplicationsController. We're shunting things
  # into a different namespace (/developer/applications) and may want to expand with more of our own logic later, so
  # we'll just cheat and copy code.
  
  skip_before_action :authenticate_admin!
  layout 'application'

  def index
    @applications = Doorkeeper.config.application_model.accessible_by(current_ability).ordered_by(:created_at)

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
    @application = Doorkeeper.config.application_model.new
  end

  def create
    @application = Doorkeeper.config.application_model.new(application_params)
    @application.owner = current_user

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications create])
      flash[:application_secret] = @application.plaintext_secret

      respond_to do |format|
        format.html { redirect_to oauth_application_url(@application) }
        format.json { render json: @application, as_owner: true }
      end
    else
      respond_to do |format|
        format.html { render :new }
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
        format.html { render :edit }
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
    @application = Doorkeeper.config.application_model.find(params[:id])

    authorize! :show, @application
  end

  def application_params
    params.require(:doorkeeper_application)
          .permit(:name, :redirect_uri, { scopes: [] }, :confidential, :public)
  end
end
