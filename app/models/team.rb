class Team < ApplicationRecord
  has_many :team_memberships
  has_many :users, :through => :team_memberships

  has_many :oauth_client_applications, :class_name => 'Oauth::ClientApplication', :as => :owner
end
