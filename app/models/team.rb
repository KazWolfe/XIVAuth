class Team < ApplicationRecord
  TEAM_DEPTH_LIMIT = 5
  TEAM_SUBTEAM_LIMIT = 5

  has_one :profile, class_name: "Team::Profile", dependent: :destroy, required: true, autosave: true

  belongs_to :parent, class_name: "Team", optional: true
  has_many :subteams, class_name: "Team", foreign_key: "parent_id", dependent: :destroy

  has_many :direct_memberships, class_name: "Team::Membership"
  has_many :direct_members, through: :direct_memberships, source: :user

  accepts_nested_attributes_for :direct_memberships

  has_many :invite_links, class_name: "Team::InviteLink", dependent: :destroy

  has_many :oauth_applications, class_name: "OAuth::ClientApplication", as: :owner

  validates :name, presence: true
  validate :validate_subteam_or_has_admin

  validate :team_recursion_control

  before_create do
    build_profile
    true
  end

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

  def antecedent_team_ids
    team_ids = []
    current = self.parent

    while current
      team_ids << current.id
      current = current.parent
    end

    team_ids
  end

  def antecedent_memberships
    self.resolve_antecedent_memberships
  end

  def antecedent_members
    User.where(id: antecedent_memberships.reselect(:user_id))
        .reorder(nil)
  end

  def descendant_team_ids
    # teams can't have children without a known self id, so we can be lazy
    return [] if self.id.blank?

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

  private def validate_subteam_or_has_admin
    return unless self.parent_id.nil?

    # Consider in-memory built memberships (including nested attributes) so validation
    # works before persistence. Avoid querying only the DB.
    has_admin = self.direct_memberships.any? { |m| m.role.to_s == "admin" }
    errors.add(:base, "Root teams must have at least one admin") unless has_admin
  end

  private def check_team_loop
    return if self.parent_id.nil? || self.id.nil?

    if self.parent_id == self.id
      errors.add(:parent_id, "cannot be the same as the team itself")
      return
    end

    children = Team.where(parent_id: self.id)
    while children.any?
      if children.any? { |t| t.id == self.parent_id }
        errors.add(:parent_id, "cannot create a recursive hierarchy")
      end

      children = Team.where(parent_id: children.pluck(:id))
    end
  end

  private def team_recursion_control
    return if self.parent_id.blank?

    # ensure we don't have a loop before doing our recursion checks
    self.check_team_loop
    return if errors.any?

    if Team.where(parent_id: self.parent_id).count >= TEAM_SUBTEAM_LIMIT
      errors.add(:parent_id, "cannot have more than #{TEAM_SUBTEAM_LIMIT} direct subteams")
    end

    # Disallow depth of n+ (i.e., great-grandchildren)
    if antecedent_team_ids.length >= TEAM_DEPTH_LIMIT
      errors.add(:parent_id, "cannot be more than #{TEAM_DEPTH_LIMIT} levels deep")
    end
  end
end
