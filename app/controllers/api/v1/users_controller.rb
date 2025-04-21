class Api::V1::UsersController < Api::V1::ApiController
  before_action -> { doorkeeper_authorize! :user }
  before_action :check_resource_owner_presence

  before_action only: %i[jwt] do
    doorkeeper_authorize! "user:jwt", "user:manage"
  end

  def show
    @user = current_user
    @social_identities = authorized_social_identities if doorkeeper_token.scopes.exists?("user:social")
  end

  def jwt
    @user = current_user

    issued_at = Time.now.to_i
    payload = {
      jti: SecureRandom.urlsafe_base64(24, padding: false),
      iss: ENV.fetch("APP_URL", "https://xivauth.net"),
      sub: @user.id,
      verified: @user.character_registrations.verified.count.positive?,
      iat: issued_at,
      exp: issued_at + 600,
    }

    payload[:nonce] = params[:nonce] if params[:nonce].present?

    algorithm = params[:algorithm] || JwtSigningKey::DEFAULT_ALGORITHM
    signing_key = JwtSigningKey.preferred_key_for_algorithm(algorithm)
    unless signing_key.present?
      render json: { error: "Algorithm is not valid, or a key does not exist for it." }, status: :unprocessable_entity
      return
    end

    jwt_token = JWT.encode(payload, signing_key.private_key, algorithm, kid: signing_key.name, typ: "User")

    render json: { token: jwt_token }
  end

  private def authorized_social_identities
    result = []
    policy = @doorkeeper_token.permissible_policy

    @user.social_identities.each do |identity|
      next if policy.present? && !policy.can_access_resource?(identity)

      result << identity
    end

    result
  end
end
