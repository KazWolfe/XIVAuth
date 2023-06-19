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
    @characters = @authorized_characters

    sp = search_params
    @characters = @characters.joins(:character).where(character: sp.to_hash) if sp.present?
  end

  def show; end

  def create
    ffxiv_character = FFXIV::Character.for_lodestone_id(params[:lodestone_id])
    @character = CharacterRegistration.new(character: ffxiv_character, user: current_user)

    if @character.save
      render :show, status: :created, location: @character
    else
      render json: @character.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @character
  end

  def destroy
    authorize! :destroy, @character

    @character.destroy

    head :no_content
  end

  def verify
    authorize! :update, @character

    if FFXIV::VerifyCharacterRegistrationJob.perform_later @character
      head status: :created
    else
      head status: :internal_server_error
    end
  end

  def unverify
    authorize! :update, @character

    @character.verified_at = nil

    if @character.save
      head status: :no_content
    else
      render json: @character.errors, status: :unprocessable_entity
    end
  end
  
  def jwt
    render json: { "jwt": 'hi' }
  end

  private

  def load_authorized_characters
    @authorized_characters = CharacterRegistration.accessible_by(current_ability)
    @authorized_characters = @authorized_characters.verified unless character_manage?

    # TODO: scoping
  end

  def set_character
    @character = @authorized_characters
                   .joins(:character)
                   .where(character: { lodestone_id: params[:lodestone_id] })
                   .first
  end

  def search_params
    allowlist = %i[name home_world data_center]
    allowlist << :content_id if character_manage?

    params.permit(allowlist)
  end

  def character_manage?
    doorkeeper_token[:scopes].include? 'character:manage'
  end
end
