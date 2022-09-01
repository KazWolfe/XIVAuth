class User < ApplicationRecord
  has_many :characters

  has_many :team_memberships
  has_many :teams, :through => :team_memberships

  has_many :oauth_client_applications, :class_name => 'Oauth::ClientApplication', :as => :owner

  devise :database_authenticatable, :registerable, :confirmable, :omniauthable,
         :recoverable, :rememberable, :validatable, :zxcvbnable, :omniauth_providers => [:discord, :steam]

end
