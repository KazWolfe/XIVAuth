class Team < ApplicationRecord
  has_one :profile, class_name: 'Team::Profile', foreign_key: 'team_id', dependent: :destroy

  belongs_to :parent, class_name: 'Team', optional: true
  has_many :subteams, class_name: 'Team', foreign_key: 'parent_id', dependent: :destroy

  has_many :direct_memberships, class_name: 'Team::Membership', foreign_key: 'team_id'
  has_many :direct_members, through: :direct_memberships, source: :user

  has_many :oauth_applications, class_name: 'OAuth::ClientApplication', as: :owner

  # Get all memberships for this team, including ones from inherited teams.
  def antecedent_and_own_memberships(deduplicate: true)
    # blame gpt-5 for whatever the hell this is. it passes tests soooo????
    return all_memberships_inner unless deduplicate

    dedup = Team::Membership
      .from("(#{all_memberships_inner.reorder(nil).to_sql}) team_memberships")
      .select('DISTINCT ON (team_memberships.user_id) team_memberships.*')
      .order(Arel.sql("team_memberships.user_id, #{Team::Membership.generate_case_for_role_ranking} DESC"))

    Team::Membership
      .from("(#{dedup.to_sql}) team_memberships")
      .select('team_memberships.*')
  end

  def antecedent_and_own_members
    User.joins(:team_memberships)
        .merge(antecedent_and_own_memberships)
        .reselect('users.*')
        .distinct
        .reorder(nil)
  end

  def descendant_and_own_memberships
    # Collect this team and all descendant team IDs iteratively to avoid deep Ruby recursion
    team_ids = []
    frontier = [self.id].compact

    while frontier.any?
      team_ids.concat(frontier)
      frontier = Team.where(parent_id: frontier).ids
    end

    return Team::Membership.none if team_ids.empty?

    Team::Membership.where(team_id: team_ids)
  end

  def descendant_and_own_members
    # Build a chainable relation of Users from the memberships relation
    User.joins(:team_memberships)
        .merge(descendant_and_own_memberships)
        .reselect('users.*')
        .distinct
        .reorder(nil)
  end

  def readonly?
    super || (!new_record? && is_special_id?)
  end

  protected def all_memberships_inner
    if inherit_parent_memberships
      direct_memberships.or(parent&.all_memberships_inner || Team::Membership.none)
    else
      direct_memberships.or(parent&.admin_memberships || Team::Membership.none)
    end
  end

  protected def admin_memberships
    direct_memberships.admin.or(parent&.admin_memberships || Team::Membership.none)
  end

  # Check if this ID is a special UUID of the form 00000000-0000-8000-8f0f-0000xxxxxxxx
  # where x is any hex digit. This is used to mark internal or system teams that should
    # not be edited by the app.
  protected def is_special_id?
    return false if self.id.nil?

    (self.id.gsub("-", "").to_i(16) >> 32) == 0x8000_8f0f_0000
  end
end