class Team < ApplicationRecord
  has_one :profile, class_name: "Team::Profile", dependent: :destroy, required: true, autosave: true

  belongs_to :parent, class_name: "Team", optional: true
  has_many :subteams, class_name: "Team", foreign_key: "parent_id", dependent: :destroy

  has_many :direct_memberships, class_name: "Team::Membership"
  has_many :direct_members, through: :direct_memberships, source: :user

  has_many :oauth_applications, class_name: "OAuth::ClientApplication", as: :owner

  def profile
    super || build_profile
  end
  
  def active_memberships
    self.direct_memberships.active
  end
  
  def active_members
    User.where(id: active_memberships.reselect(:user_id))
        .reorder(nil)
  end

  # Get all memberships for this team, including ones from inherited teams.
  def antecedent_memberships
    self.resolve_antecedent_memberships
  end

  def antecedent_members
    User.where(id: antecedent_memberships.reselect(:user_id))
        .reorder(nil)
  end

  def descendant_team_ids
    # Collect descendant team IDs iteratively (exclude self)
    team_ids = []
    frontier = Team.where(parent_id: self.id).ids

    while frontier.any?
      team_ids.concat(frontier)
      frontier = Team.where(parent_id: frontier).ids
    end

    team_ids
  end

  def descendant_memberships
    Team::Membership.where(team_id: descendant_team_ids).active
  end

  def descendant_members
    User.where(id: descendant_memberships.reselect(:user_id))
        .reorder(nil)
  end

  def all_members(include_antecedents: true, include_descendants: false)
    scope = User.where(id: self.direct_memberships.reselect(:user_id))

    scope = scope.or(User.where(id: antecedent_memberships.reselect(:user_id))) if include_antecedents
    scope = scope.or(User.where(id: descendant_memberships.reselect(:user_id))) if include_descendants

    scope.distinct
  end

  def readonly?
    super || (!new_record? && is_special_id?)
  end

  protected def resolve_antecedent_memberships(admin_only: false, recursing: false)
    base = if recursing
             admin_only ? self.direct_memberships.admins : self.direct_memberships.active
           else
             Team::Membership.none
           end

    if self.parent
      only_search_admins = admin_only || !self.inherit_parent_memberships
      antecedents = self.parent.resolve_antecedent_memberships(admin_only: only_search_admins, recursing: true)

      antecedents.or(base)
    else
      base
    end
  end

  # Check if this ID is a special UUID of the form 00000000-0000-8000-8f0f-0000xxxxxxxx
  # where x is any hex digit. This is used to mark internal or system teams that should
  # not be edited by the app.
  protected def is_special_id?
    return false if self.id.nil?

    (self.id.gsub("-", "").to_i(16) >> 32) == 0x8000_8f0f_0000
  end
end
