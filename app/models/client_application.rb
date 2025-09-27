class ClientApplication < ApplicationRecord
  belongs_to :owner, polymorphic: true, optional: true

  has_one :profile, class_name: "ClientApplication::Profile", dependent: :destroy, required: true, autosave: true,
          foreign_key: :application_id, inverse_of: :application

  has_many :oauth_clients, class_name: "ClientApplication::OAuthClient", dependent: :destroy,
           foreign_key: :application_id, inverse_of: :application
  has_many :acls, class_name: "ClientApplication::AccessControlList", dependent: :destroy,
           foreign_key: :application_id, inverse_of: :application

  validates_associated :profile
  accepts_nested_attributes_for :profile, update_only: true

  def profile
    super || build_profile
  end

  def verified?
    self.verified_at.present?
  end

  def usable_by?(user)
    return true if owner.nil? || !self.private?
    return true if owner.is_a?(User) && owner == user
    return true if owner.is_a?(Team) && owner.direct_members.include?(user)

    user_match = acls.find_by(principal: user)
    if user_match
      return !user_match.deny?
    end

    # evaluate teams
    acls.where(principal_type: "Team").order(deny: :desc).each do |a|
      team = a.principal
      next if team.nil?

      if team.all_members(include_antecedents: !a.deny?, include_descendants: a.include_team_descendants).include?(user)
        return !a.deny?
      end
    end

    false
  end
end