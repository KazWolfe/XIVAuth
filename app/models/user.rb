class User < ApplicationRecord
  has_many :characters

  has_many :team_memberships
  has_many :teams, through: :team_memberships

  after_touch :reload

  has_many :oauth_client_applications, class_name: 'Oauth::ClientApplication', as: :owner

  devise :database_authenticatable, :registerable, :confirmable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :zxcvbnable, 
         :omniauth_providers => [:discord, :steam]

  def pairwise_id(client_id)
    digest = OpenSSL::Digest.new('sha256')
    hmac = OpenSSL::HMAC.digest(digest, 'secret', "#{self.id}###{client_id}")

    Base64.urlsafe_encode64(hmac, padding: false)
  end
end
