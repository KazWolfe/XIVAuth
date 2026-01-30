class Developer::TeamsController < Developer::DeveloperPortalController
  layout "portal/base"
  include Pagy::Method

  before_action :load_parent_teams, only: %i[new create]
  before_action :set_team, only: %i[show edit update destroy regenerate]

  def index
    @pagy, @teams = pagy(current_user.associated_teams.order(created_at: :desc), items: 12)

    respond_to do |format|
      format.html { render :index }
      format.json { head :no_content }
    end
  end

  def new
    @team = Team.new
    @team.parent_id = params[:parent_id] if params[:parent_id].present?
  end

  def create
    @team = Team.new(create_team_params)

    if @team.parent_id.blank?
      @team.direct_memberships.build(user: current_user, role: "admin")
    else
      unless @available_parent_teams.find_by(id: @team.parent_id)
        @team.errors.add(:parent_id, "you must be an admin of the parent team")
        return render :new, status: :unprocessable_entity
      end
    end

    if @team.save
      redirect_to developer_team_path(@team), notice: "Team was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render json: @team, as_owner: true }
    end
  end

  def update
    authorize! :update, @team

    if @team.readonly?
      flash[:alert] = "This is a system team and cannot be modified."
      redirect_to developer_team_path(@team)
    elsif @team.update(update_team_params)
      flash[:notice] = "Team updated successfully."
      redirect_to developer_team_path(@team)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @team

    if @team.destroy
      flash[:notice] = "Team destroyed."
    else
      flash[:alert] = @team.errors.full_messages.first || "Unable to delete team"
    end

    respond_to do |format|
      format.html { redirect_to developer_teams_url }
      format.json { head :no_content }
    end
  end

  private def set_team
    @team = Team.find(params[:id])

    authorize! :show, @team
  end

  private def load_parent_teams
    @available_parent_teams = current_user.teams_by_membership_scope(:admins)
                                          .order(:name)
                                          .distinct
  end

  private def create_team_params
    params.require(:team).permit(:name, :parent_id)
  end

  private def update_team_params
    params.require(:team).permit(:name)
  end
end
