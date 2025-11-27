class Developer::TeamsController < Developer::DeveloperPortalController
  layout "portal/page"
  include Pagy::Method

  before_action :set_team, only: %i[show edit update destroy regenerate]

  def index
    @pagy, @teams = pagy(current_user.teams.order(created_at: :desc), items: 12)

    respond_to do |format|
      format.html { render :index, layout: "portal/base" }
      format.json { head :no_content }
    end
  end

  def show; end

  private def set_team
    @team = Team.find(params[:id])

    # specifically show RecordNotFound if we can't see it, rather than 403.
    raise ActiveRecord::RecordNotFound unless can? :show, @team
  end
end
