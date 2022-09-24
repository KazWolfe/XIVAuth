class Api::CharactersController < ApiController
  before_action -> { doorkeeper_authorize! :character, 'character:all', 'character:manage', 'character:jwt' }
  before_action(only: [:jwt]) { doorkeeper_authorize! 'character:jwt' }
  before_action(only: [:create, :update, :jwt]) { doorkeeper_authorize! 'character:manage' }

  def index
    characters = authorized_characters
    characters = characters.first(1) unless show_all_characters?

    respond_with(characters.map { |c| filtered_character(c) })
  end

  def show
    @character = authorized_characters.find_by(lodestone_id: params[:id])
    respond_with(nil, status: :not_found) and return unless @character.present?

    authorize! :show, @character

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
    respond_with(nil, status: :not_found) and return unless @character.present?

    authorize! :update, @character

    respond_with filtered_character(@character)
  end

  def jwt
    @character = authorized_characters.find_by(lodestone_id: params[:id])
    respond_with(nil, status: :not_found) and return unless @character.present?

    authorize! :show, @character
  end

  protected

  def filtered_character(character)
    resp = {
      id: character.user_unique_id,
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
    resp[:verification_key] = character.verification_key unless character.verified? || !can?(:verify, character)

    resp
  end

  def authorized_characters
    # Resolution path is to evaluate all denies, then all allows (if they exist).
    # Deny and allow records -> only allows that aren't also denied
    # Deny only -> all characters not listed in deny
    # Allow only -> only allows

    characters = current_user.characters
    return characters if doorkeeper_token.scopes.include?('character:manage')

    permissibles = doorkeeper_token.oauth_permissibles.where(resource_type: 'Character')

    explicit_allow_ids = permissibles.where(deny: false).pluck(:resource_id)
    explicit_deny_ids = permissibles.where(deny: true).pluck(:resource_id)

    characters = characters.verified.where.not(id: explicit_deny_ids)
    characters = characters.where(id: explicit_allow_ids) if explicit_allow_ids.present?

    characters
  end

  def show_all_characters?
    (doorkeeper_token.scopes & %w[character:manage character:all]).count.positive?
  end
end
