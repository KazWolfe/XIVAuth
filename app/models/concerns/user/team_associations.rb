module User::TeamAssociations
  extend ActiveSupport::Concern

  # Returns all teams where the user is an admin (directly or via parent team inheritance)
  # Admin permissions always cascade down to child teams regardless of inherit_parent_memberships
  def admin_teams
    # Get teams where user is directly an admin
    direct_admin_team_ids = team_memberships.admins.joins(:team).pluck(:team_id)
    return Team.none if direct_admin_team_ids.empty?

    # Collect all admin team IDs including descendants
    all_admin_team_ids = Set.new(direct_admin_team_ids)

    # Find all descendants of admin teams (admins have full access to all child teams)
    team_ids = direct_admin_team_ids
    while team_ids.present?
      descendants = Team.where(parent_id: team_ids).pluck(:id)
      break if descendants.empty?

      all_admin_team_ids.merge(descendants)
      team_ids = descendants
    end

    Team.where(id: all_admin_team_ids.to_a)
  end

  def associated_teams
    # Start with direct team memberships
    direct_teams = teams

    # Get all team IDs, starting with direct memberships
    all_team_ids = Set.new(direct_teams.pluck(:id))

    # Handle admin memberships (always inherited regardless of inherit flag)
    admin_team_ids = team_memberships.admins.joins(:team).pluck(:team_id)
    if admin_team_ids.present?
      # Find all descendants of admin teams
      team_ids = admin_team_ids
      while team_ids.present?
        descendants = Team.where(parent_id: team_ids).pluck(:id)
        break if descendants.empty?

        all_team_ids.merge(descendants)
        team_ids = descendants
      end
    end

    # Handle non-admin memberships (respect inherit flag)
    non_admin_team_ids = direct_teams.where.not(id: admin_team_ids).pluck(:id)
    if non_admin_team_ids.present?
      # Find inheritable descendants
      team_ids = non_admin_team_ids
      while team_ids.present?
        descendants = Team.where(parent_id: team_ids, inherit_parent_memberships: true).pluck(:id)
        break if descendants.empty?

        all_team_ids.merge(descendants)
        team_ids = descendants
      end
    end

    # Return all associated teams
    Team.where(id: all_team_ids.to_a)
  end
end
