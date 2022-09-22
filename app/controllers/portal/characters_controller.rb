class Portal::CharactersController < ApplicationController
  before_action :authenticate_user!
  respond_to :html, :json

  def index
    @characters = current_user.characters.unscope(:order).order('verified_at DESC NULLS LAST, created_at ASC')

    respond_with @characters
  end

  def show
    @character = Character.find(params[:id])
    authorize! :show, @character

    respond_with @character
  end

  def new
    @character = Character.new
  end

  def create
    lodestone_id = helpers.extract_id(params[:character][:lodestone_url])
    render_new_form_again(status: :unprocessable_entity) and return unless lodestone_id.present?

    if helpers.user_at_character_allowance(current_user)
      Rails.logger.warn 'User was at character allowance, blocking creation of new character', current_user
      redirect_to characters_path
    end

    @character = Character.new(lodestone_id: lodestone_id, user_id: current_user.id)

    begin
      @character.retrieve_from_lodestone!
    rescue Lodestone::CharacterNotFoundError => e
      Rails.logger.warn 'Could not find character requested by user on Lodestone', e

      respond_to do |format|
        format.turbo_stream do
          flash.now[:error] = 'The character you specified could not be found on the Lodestone. ' \
                              'Please double-check your ID or URL.'
          render_new_form_again(status: :not_found)
        end
        format.json do
          render json: { error: "Character id #{lodestone_id} was not found on lodestone" }, status: :not_found
        end
      end

      return
    end

    if @character.save
      respond_to do |format|
        format.html { redirect_to characters_path, status: :created }
        format.json { render json: @character.as_json, status: :created }
      end
    else
      respond_to do |format|
        format.html { render_new_form_again(status: :unprocessable_entity) }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @character = Character.find(params[:id])
    authorize! :update, @character

    if params[:command] == 'sync'
      render status: :forbidden and return if @character.last_lodestone_update > 24.hours.ago

      Character::SyncLodestoneJob.perform_later @character
    end

    respond_to do |format|
      format.html { redirect_to characters_path }
      format.json { render json: @character.as_json, status: :accepted }
      # we return accepted because everything we really can do here is shunted to the back
    end
  end

  def verify
    # n.b. only useful as turbo-stream/html

    @character = Character.find(params[:id])
    authorize! :verify, @character
  end

  def enqueue_verify
    @character = Character.find(params[:id])
    authorize! :verify, @character

    Character::VerifyCharacterJob.perform_later @character

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update('remote_modal-content', template: 'portal/characters/enqueue_verify')
      end

      format.json { render json: { enqueued: true }, status: :accepted }
    end
  end

  def destroy
    @character = Character.find(params[:id])
    authorize! :destroy, @character
    @character.destroy

    respond_to do |format|
      format.html { redirect_to characters_path, status: :see_other }
      format.json { render json: { deleted: true }, status: :ok }
    end
  end

  protected

  def render_new_form_again(status: :unprocessable_entity)
    render status: status,
           turbo_stream: turbo_stream.update('remote_modal-content',
                                             partial: 'portal/characters/partials/new_character_form')
  end
end
