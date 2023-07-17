class Admin::ClientApplicationsController < Admin::AdminController
  before_action :set_app, only: %i[show update destroy]

  def index
    @client_applications = OAuth::ClientApplication.order(created_at: :desc)
  end

  def show; end

  private

  def set_app
    @client_application = OAuth::ClientApplication.find(params[:id])
  end
end
