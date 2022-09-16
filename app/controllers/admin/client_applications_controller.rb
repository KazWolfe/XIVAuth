class Admin::ClientApplicationsController < AdminController
  def index
    @applications = OAuth::ClientApplication.accessible_by(current_ability)
  end

  def show
    @application = OAuth::ClientApplication.find(params[:id])
  end
end
