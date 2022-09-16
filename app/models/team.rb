class Team < ApplicationRecord
  has_many :team_memberships
  has_many :users, through: :team_memberships

  belongs_to :owner, class_name: 'User'

  after_touch :reload

  has_many :oauth_client_applications, class_name: 'OAuth::ClientApplication', as: :owner
end
