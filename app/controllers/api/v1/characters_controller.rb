class Api::V1::CharactersController < Api::V1::ApiController
  before_action { doorkeeper_authorize! 'character', 'character:all', 'character:manage', 'character:jwt' }
  before_action(except: %i[index show jwt]) { doorkeeper_authorize! 'character:manage' }
  before_action(only: %i[jwt]) { doorkeeper_authorize! 'character:jwt', 'character:manage' }

  before_action :check_resource_owner_presence
  before_action :load_authorized_characters
  before_action :set_character, except: %i[index create]

  def index
    @registrations = @authorized_registrations

    sp = search_params
    @registrations = @registrations.joins(:character).where(character: sp.to_hash) if sp.present?
  end

  def show; end

  def create
    ffxiv_character = FFXIV::Character.for_lodestone_id(params[:lodestone_id])
    @registration = CharacterRegistration.new(character: ffxiv_character, user: current_user)

    if @registration.save
      render :show, status: :created, location: @registration
    else
      render json: { errors: @registration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @registration

    @registration.character.update(update_params)

    if @registration.save
      render :show, status: :ok, location: @registration
    else
      render json: { errors: @registration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @registration

    @registration.destroy

    head :no_content
  end

  def verify
    authorize! :update, @registration

    if FFXIV::VerifyCharacterRegistrationJob.perform_later @registration
      head status: :created
    else
      head status: :internal_server_error
    end
  end

  def unverify
    authorize! :update, @registration

    @registration.verified_at = nil

    if @registration.save
      head status: :no_content
    else
      render json: { errors: @registration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def jwt
    unless @registration.verified?
      render json: { error: 'Attestations can only be generated for verified characters.' }, status: :forbidden
      return
    end

    issued_at = Time.now.to_i

    payload = {
      jti: params[:nonce] || SecureRandom.urlsafe_base64(24, padding: false),
      iat: issued_at,
      exp: issued_at + 600,
      id: @registration.character.lodestone_id,
      pk: @registration.entangled_id
    }

    algorithm = params[:algorithm] || 'ED25519'
    signing_key = JwtSigningKey.preferred_key_for_algorithm(algorithm)
    unless signing_key.present?
      render json: { error: 'Algorithm is not valid, or a key does not exist for it.' }, status: :unprocessable_entity
      return
    end

    jwt_token = JWT.encode(payload, signing_key.private_key, algorithm, kid: signing_key.name)

    render json: { token: jwt_token }
  end

  private

  def load_authorized_characters
    @authorized_registrations = CharacterRegistration.accessible_by(current_ability)

    unless character_manage?
      @authorized_registrations = @authorized_registrations.verified

      policy = @doorkeeper_token.permissible_policy

      @authorized_registrations = @authorized_registrations.verified.filter do |r|
        policy.blank? || policy.can_access_resource?(r)
      end
    end
  end

  def set_character
    character = @authorized_registrations.filter do |r|
      r.character.lodestone_id == params[:lodestone_id]
    end

    raise ActiveRecord::RecordNotFound if character[0].nil?

    @registration = character[0]
  end

  def search_params
    allowlist = %i[name home_world data_center]
    allowlist << :content_id if character_manage?

    params.permit(allowlist)
  end

  def update_params
    params.permit(:content_id)
  end

  def character_manage?
    doorkeeper_token[:scopes].include? 'character:manage'
  end
end
