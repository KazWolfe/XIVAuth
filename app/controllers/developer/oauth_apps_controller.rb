class Developer::OAuthAppsController < Doorkeeper::ApplicationsController
  skip_before_action :authenticate_admin!

  def index
    @applications = Doorkeeper.config.application_model.accessible_by(current_ability).ordered_by(:created_at)

    respond_to do |format|
      format.html
      format.json { head :no_content }
    end
  end

  def create
    super

    # FIXME: Filthy hack, but it works. hopefully.
    @application.owner = current_user
    @application.save
  end

  def update
    authorize! :edit, @application
    super
  end

  def destroy
    authorize! :destroy, @application
    super
  end

  private

  def set_application
    super
    authorize! :show, @application
  end
end
