class User < ApplicationRecord
  include OmniauthAuthenticable
  include SystemRoleable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :trackable, :recoverable,
         :rememberable, :validatable,
         :omniauthable

  default_scope { order(created_at: :asc) }

  has_many :social_identities, dependent: :destroy
  has_many :character_registrations, dependent: :destroy

  has_many :webauthn_credentials, class_name: 'Users::WebauthnCredential', dependent: :destroy
  has_one :totp_credential, class_name: 'Users::TotpCredential', dependent: :destroy

  def admin?
    # FIXME: This is terrible.
    email == 'dev@eorzea.id' || email.end_with?('kazwolfe.io')
  end

  # Check if the user has permission to access developer functions, like the ability to register OAuth applications.
  def developer?
    true
  end

  def unverified_character_allowance
    5
  end

  def requires_mfa?
    webauthn_credentials.any? || totp_credential&.otp_enabled
  end

  # Get the list of providers that can be used for authentication purposes.
  def self.omniauth_login_providers
    social_only_providers = []
    
    omniauth_providers - social_only_providers
  end

  # Get a list of configured Omniauth providers that can be bound to this user.
  # Used to generate routes and other systems, so will include providers that cannot be used for authentication.
  def self.omniauth_providers
    Devise.omniauth_configs.keys & (Rails.application.credentials[:oauth]&.keys || [])
  end

  def self.signup_permitted?
    Flipper.enabled? :user_signups
  end
end
