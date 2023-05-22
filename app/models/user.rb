class User < ApplicationRecord
  include OmniauthAuthenticable
  include SystemRoleable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :trackable, :recoverable,
         :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[discord github steam]

  default_scope { order(created_at: :asc) }

  has_many :social_identities, dependent: :destroy
  has_many :character_registrations, dependent: :destroy

  has_many :webauthn_credentials, class_name: 'Users::WebauthnCredential', dependent: :destroy
  has_one :totp_credential, class_name: 'Users::TotpCredential', dependent: :destroy

  def admin?
    email == 'dev@eorzea.id'
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

  # Get a list of all social identity providers that this user can use. This is a superset of login providers and extra
  # data-only social providers (e.g. Patreon)
  def self.social_identity_providers
    social_providers = []
    # social_providers = [:patreon]
    
    omniauth_providers + social_providers
  end
end
