class User < ApplicationRecord
  has_many :social_identities, dependent: :destroy

  has_many :characters

  has_many :team_memberships
  has_many :teams, through: :team_memberships

  after_touch :reload

  has_many :oauth_client_applications, class_name: 'OAuth::ClientApplication', as: :owner

  devise :database_authenticatable, :registerable, :confirmable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :zxcvbnable,
         omniauth_providers: [:discord, :github, :steam]

  def pairwise_id(client_id)
    digest = OpenSSL::Digest.new('sha256')
    hmac = OpenSSL::HMAC.digest(digest, 'secret', "#{self.id}###{client_id}")

    Base64.urlsafe_encode64(hmac, padding: false)
  end

  def name
    "#{username}"
  end
  
  def admin?
    email == 'dev@eorzea.id'
  end
  
  def developer?
    true
  end

  def self.from_omniauth(auth)
    ident = SocialIdentity.find_by(provider: auth.provider, external_id: auth.uid)
    return ident.user if ident

    email = auth['info']['email']
    existing = find_for_database_authentication(email: email.downcase)
    if existing
      Rails.logger.info "Matched a user #{existing.id} to incoming oauth provider"

      existing.add_oauth_authorization(auth).save
      return existing
    end

    create_new_user_from_oauth(auth, email)
  end

  def self.new_with_session(params, session)
    super.tap do |u|
      if (data = session['devise.oauth.data'])
        user.email = data['info']['email'] if user.email.blank?
        user.add_oauth_authorization(data)
      end
    end
  end

  def add_oauth_authorization(data)
    social_identities.build({
                              provider: data['provider'],
                              external_id: data['uid'],
                              # external_email: data['info']['email']
                            })
  end

  private

  def self.create_new_user_from_oauth(auth, email)
    Rails.logger.info "Creating new user from oauth", auth

    user = User.new({
                      email: email,
                      username: auth['info']['nickname'] || auth['info']['name'] || email.split('@').first.gsub('.', ''),
                      password: Devise.friendly_token(32)
                    })

    user.skip_confirmation! if auth['info']['email_verified']

    user.add_oauth_authorization(auth)
    user.save

    Rails.logger.info "User created!", user

    user
  end
end
