class Team < ApplicationRecord
  has_many :team_memberships
  has_many :users, through: :team_memberships

  after_touch :reload

  has_many :oauth_client_applications, class_name: 'OAuth::ClientApplication', as: :owner
  
  def owner
    owner_membership = team_memberships.owner.first
    return nil if owner_membership.nil?
    
    owner_membership.user
  end
end
