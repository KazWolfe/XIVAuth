class User < ApplicationRecord
  include OmniauthAuthenticable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :trackable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[discord github steam]

  has_many :social_identities, dependent: :destroy
  
  has_many :character_registrations, dependent: :destroy
end
