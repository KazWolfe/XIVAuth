class User < ApplicationRecord
  include OmniauthAuthenticable
  include SystemRoleable

  devise :database_authenticatable, :registerable,
         :confirmable, :trackable, :recoverable,
         :rememberable, :validatable, :zxcvbnable,
         :omniauthable

  default_scope { order(created_at: :asc) }

  validates :email, exclusion: { in: Users::SessionsHelper::RANDOM_NPC_EMAILS, message: " is an NPC's email.... Nice try." }

  has_many :social_identities, class_name: "User::SocialIdentity", dependent: :destroy
  has_many :character_registrations, dependent: :destroy

  has_many :webauthn_credentials, class_name: "User::WebauthnCredential", dependent: :destroy
  has_one :totp_credential, class_name: "User::TotpCredential", dependent: :destroy
  validates :webauthn_id, uniqueness: true, allow_nil: true

  has_one :profile, class_name: "User::Profile", dependent: :destroy, required: true, autosave: true
  validates_associated :profile
  accepts_nested_attributes_for :profile, update_only: true

  has_many :team_memberships, class_name: "Team::Membership", dependent: :destroy
  has_many :teams, through: :team_memberships, source: :team

  has_many :oauth_authorizations, class_name: "OAuth::AccessToken", foreign_key: "resource_owner_id",
           inverse_of: :resource_owner, dependent: :destroy

  def profile
    super || build_profile
  end

  def admin?
    self.role? :admin
  end

  # Check if the user has permission to access developer functions, like the ability to register OAuth applications.
  def developer?
    self.role?(:developer)
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

  def display_name
    profile.display_name
  end

  def avatar_url
    gravatar_url(144)
  end

  def gravatar_url(size = 32, fallback: "retro", rating: "pg")
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "https://secure.gravatar.com/avatar/#{hash}.png?s=#{size}&d=#{fallback}&r=#{rating}"
  end

  # Overrides Devise's Validatable#password_required?
  def password_required?
    # Don't require a password for validation for new users if a social identity is present
    return false if !persisted? && !social_identities.empty?

    # Don't require a password for validation if the user does not have a password
    return false if persisted? && !has_password?

    super
  end

  # def skip_password_complexity?
  #   false
  # end

  def associated_teams
    # Start with direct team memberships
    direct_teams = teams

    # Get all team IDs, starting with direct memberships
    all_team_ids = Set.new(direct_teams.pluck(:id))

    # Handle admin memberships (always inherited regardless of inherit flag)
    admin_team_ids = team_memberships.admins.joins(:team).pluck(:team_id)
    if admin_team_ids.present?
      # Find all descendants of admin teams
      team_ids = admin_team_ids
      while team_ids.present?
        descendants = Team.where(parent_id: team_ids).pluck(:id)
        break if descendants.empty?

        all_team_ids.merge(descendants)
        team_ids = descendants
      end
    end

    # Handle non-admin memberships (respect inherit flag)
    non_admin_team_ids = direct_teams.where.not(id: admin_team_ids).pluck(:id)
    if non_admin_team_ids.present?
      # Find inheritable descendants
      team_ids = non_admin_team_ids
      while team_ids.present?
        descendants = Team.where(parent_id: team_ids, inherit_parent_memberships: true).pluck(:id)
        break if descendants.empty?

        all_team_ids.merge(descendants)
        team_ids = descendants
      end
    end

    # Return all associated teams
    Team.where(id: all_team_ids.to_a)
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
