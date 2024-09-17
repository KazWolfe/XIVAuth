class User < ApplicationRecord
  include OmniauthAuthenticable
  include SystemRoleable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :trackable, :recoverable,
         :rememberable, :validatable, :zxcvbnable,
         :omniauthable

  default_scope { order(created_at: :asc) }

  has_many :social_identities, class_name: "Users::SocialIdentity", dependent: :destroy
  has_many :character_registrations, dependent: :destroy

  has_many :webauthn_credentials, class_name: "Users::WebauthnCredential", dependent: :destroy
  has_one :totp_credential, class_name: "Users::TotpCredential", dependent: :destroy

  has_one :profile, class_name: "Users::Profile", dependent: :destroy, required: true, autosave: true
  validates_associated :profile
  accepts_nested_attributes_for :profile, update_only: true

  def profile
    super || build_profile
  end

  def admin?
    self.has_role? :admin
  end

  # Check if the user has permission to access developer functions, like the ability to register OAuth applications.
  def developer?
    true
  end

  def unverified_character_allowance
    5
  end

  def requires_mfa?
    webauthn_credentials.any? || totp_credential&.otp_enabled || false
  end

  # Check if the user has a defined encrypted password. If not, this user is considered oauth-only and cannot
  # use certain login features.
  def has_password?
    self.encrypted_password.present?
  end

  def avatar_url(size = 32, options: { })
    gravatar_url(size, *options)
  end

  def gravatar_url(size = 32, fallback: "retro", rating: "pg")
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "https://secure.gravatar.com/avatar/#{hash}.png?s=#{size}&d=#{fallback}&r=#{rating}"
  end

  # Overrides Devise's Validatable#password_required?
  def password_required?
    # Don't require a password for validation for new users if a social identity is present
    return false if !persisted? and not social_identities.empty?

    # Don't require a password for validation if the user does not have a password
    return false if persisted? and !has_password?

    super
  end

  # Get the list of providers that can be used for authentication purposes.
  def self.omniauth_login_providers
    social_only_providers = [:patreon]

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
