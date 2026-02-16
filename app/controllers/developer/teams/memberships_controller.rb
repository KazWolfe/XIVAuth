class Developer::Teams::MembershipsController < Developer::DeveloperPortalController
  before_action :set_team
  before_action :set_membership

  def update
    authorize! :manage, @team
    @membership.update(membership_params)

    respond_to do |format|
      format.turbo_stream
      format.html do
        if @membership.errors.any?
          redirect_to developer_team_path(@team), alert: @membership.errors.full_messages.first
        else
          redirect_to developer_team_path(@team), notice: "Role updated."
        end
      end
    end
  end

  def destroy
    authorize! :manage, @team

    if @membership.user == current_user
      return redirect_to developer_team_path(@team), alert: "You cannot remove yourself from a team."
    end

    # First request: show confirmation modal
    render and return if request.format.turbo_stream? && params[:commit].blank?

    if @membership.destroy
      respond_to do |format|
        format.turbo_stream { render :destroy_confirmed }
        format.html { redirect_to developer_team_path(@team), notice: "Member removed." }
      end
    else
      redirect_to developer_team_path(@team), alert: @membership.errors.full_messages.first
    end
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
    authorize! :use, @team
  end

  def set_membership
    @membership = @team.direct_memberships.find_by!(user_id: params[:user_id])
  end

  def membership_params
    params.require(:team_membership).permit(:role).tap do |p|
      allowed = %w[admin developer member]
      p[:role] = nil unless allowed.include?(p[:role])
    end
  end
end
