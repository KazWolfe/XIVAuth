class Api::CharactersController < ApiController
  before_action -> { doorkeeper_authorize! :character, 'character:all', 'character:manage' }
  before_action only: [:create, :update, :show] do
    doorkeeper_authorize! 'character:manage'
  end

  def index
    @characters = current_user.characters
    @characters = @characters.verified.where(id: permissible_character_ids) unless show_unverified?

    respond_with(@characters.map { |c| filtered_character(c) })
  end

  def show
    @character = Character.find_by(lodestone_id: params[:id], user_id: current_user.id)
    authorize! :show, @character

    respond_with(status: :not_found) unless @character.verified? || show_unverified?

    respond_with filtered_character(@character)
  end

  def create
    params.require([:content_id, :character_name, :home_world])

    character_name = params[:character_name]
    home_world = params[:home_world].titleize

    lodestone_id = Lodestone.search_for_lodestone_id(character_name, home_world)

    @character = Character.create(
      lodestone_id: lodestone_id,
      user_id: current_user.id,
      character_name: character_name,
      home_world: home_world,
      content_id: params[:content_id].to_i
    )

    respond_with filtered_character(@character)
  end

  def update
    params.require(:user).permit(:content_id)

    @character = Character.find_by(lodestone_id: params[:id])
    authorize! :update, @character

    respond_with filtered_character(@character)
  end

  def filtered_character(character)
    resp = {
      lodestone_id: character.lodestone_id,
      character_name: character.character_name,
      home_world: character.home_world,
      home_datacenter: character.home_datacenter,
      avatar_url: character.avatar_url,
      verified: character.verified?,
      last_update: character.updated_at
    }

    # There's an implicit block here for character:manage, as only verified characters will normally pass through here
    # unless the access token in question already can see unverified characters
    resp[:verification_key] = character.verification_key unless
      character.verified? || !can?(:verify, character)

    resp
  end

  def show_unverified?
    doorkeeper_token[:scopes].include?('character:manage')
  end

  def permissible_character_ids
    doorkeeper_token.oauth_permissibles.where(resource_type: 'Character').pluck(:resource_id)
  end
end
