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

  # Get a list of all social identity providers that this user can use. This is a superset of login providers and extra
  # data-only social providers (e.g. Patreon)
  def self.social_identity_providers
    social_providers = []
    # social_providers = [:patreon]
    
    omniauth_providers + social_providers
  end

  # Get a list of all Social Identity providers that can be used *for login* to XIVAuth accounts.
  def self.omniauth_providers
    # ToDo: figure out a good way to restrict this (?)
    allowed_signin_providers = Devise.omniauth_configs.keys
    configured_providers = Rails.application.credentials.dig(:oauth)&.keys || []

    allowed_signin_providers & configured_providers
  end
end
