class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :trackable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[discord github steam]
end
