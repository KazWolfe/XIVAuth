class Developer::ClientAppsController < Developer::DeveloperPortalController
  layout "portal/base"
  include Pagy::Method
  helper Doorkeeper::DashboardHelper

  before_action :load_available_owners, only: %i[new create]
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

    # Set owner based on owner_id parameter
    # Blank/nil = current user, otherwise must be a team ID where user is a developer
    if create_application_params[:owner_id].present?
      owner = current_user.teams_by_membership_scope(:developers)
                          .find_by(id: create_application_params[:owner_id])
      unless owner
        @application.errors.add(:owner_id, "you must be a developer of the selected team")
        return render :new, status: :unprocessable_entity
      end
      @application.owner = owner
    else
      @application.owner = current_user
    end

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications create])

      respond_to do |format|
        format.html { redirect_to developer_application_path(@application) }
        format.json { render json: @application, as_owner: true }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json do
          errors = @application.errors.full_messages

          render json: { errors: }, status: :unprocessable_content
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

          render json: { errors: errors }, status: :unprocessable_content
        end
      end
    end
  end

  private def load_available_owners
    # Build owner options: current user + teams where user is a developer
    @available_owners = [["Your Account", ""]]

    current_user.teams_by_membership_scope(:developers).order(:name).each do |team|
      @available_owners << [team.name, team.id]
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
          .permit(:name, :private, profile_attributes: [:homepage_url, :privacy_policy_url, :terms_of_service_url])
  end

  private def create_application_params
    params.require(:client_application)
          .permit(:name, :private, :owner_id,
                  profile_attributes: [:homepage_url, :privacy_policy_url, :terms_of_service_url])
  end
end
