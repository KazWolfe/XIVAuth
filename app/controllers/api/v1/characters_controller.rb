class Api::V1::CharactersController < Api::V1::ApiController
  before_action -> { doorkeeper_authorize! 'character', 'character:all', 'character:manage', 'character:jwt' }
  before_action(only: %i[create update]) { doorkeeper_authorize! 'character:manage' }

  before_action :check_resource_owner_presence
  before_action :load_authorized_characters
  before_action :set_character, except: %i[index create]

  before_action except: %i[index show jwt] do
    doorkeeper_authorize! 'character:manage'
  end

  before_action only: %i[jwt] do
    doorkeeper_authorize! 'user:jwt', 'user:manage'
  end

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
      render json: @registration.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @registration

    @registration.character.update(update_params)

    if @registration.save
      render :show, status: :ok, location: @registration
    else
      render json: @registration.errors, status: :unprocessable_entity
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
      render json: @registration.errors, status: :unprocessable_entity
    end
  end
  
  def jwt
    render json: { "jwt": 'hi' }
  end

  private

  def load_authorized_characters
    @authorized_registrations = CharacterRegistration.accessible_by(current_ability)
    @authorized_registrations = @authorized_registrations.verified unless character_manage?

    # TODO: scoping
  end

  def set_character
    @registration = @authorized_registrations
                   .joins(:character)
                   .where(character: { lodestone_id: params[:lodestone_id] })
                   .first!
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
