module User::TeamAssociations
  extend ActiveSupport::Concern

  # Returns all teams where the user has the specified role (directly or via parent team inheritance)
  # @param scope [Symbol] The membership scope to use (:admins, :developers, :active)
  # @return [ActiveRecord::Relation<Team>]
  def teams_by_membership_scope(scope)
    ignore_inherit = scope.in?(%i[admins managers])

    # Get teams where user has the specified role
    direct_team_ids = team_memberships.public_send(scope).joins(:team).pluck(:team_id)
    return Team.none if direct_team_ids.empty?

    # Collect all team IDs including descendants
    all_team_ids = Set.new(direct_team_ids)

    # Find descendants (admins ignore inherit flag, all others respect it)
    team_ids = direct_team_ids
    while team_ids.present?
      descendants = if ignore_inherit
                      Team.where(parent_id: team_ids).pluck(:id)
                    else
                      Team.where(parent_id: team_ids, inherit_parent_memberships: true).pluck(:id)
                    end
      break if descendants.empty?

      all_team_ids.merge(descendants)
      team_ids = descendants
    end

    Team.where(id: all_team_ids.to_a)
  end

  def associated_teams
    all_team_ids = Set.new

    all_team_ids.merge(teams_by_membership_scope(:admins).pluck(:id))
    all_team_ids.merge(teams_by_membership_scope(:active).pluck(:id))

    Team.where(id: all_team_ids.to_a)
  end
end
