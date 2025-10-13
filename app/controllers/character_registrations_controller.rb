class CharacterRegistrationsController < ApplicationController
  include Pagy::Backend

  layout "portal/page"
  before_action :set_character_registration, only: %i[show destroy]

  # GET /character_registrations or /character_registrations.json
  def index
    @pagy, @character_registrations = pagy(CharacterRegistration.where(user: current_user), items: 12)

    render :index, layout: "portal/base"
  end

  # GET /character_registrations/new
  def new
    @character_registration = CharacterRegistration.new
  end

  # POST /character_registrations or /character_registrations.json
  def create
    lodestone_data = helpers.extract_data(character_registration_params[:character_key])
    ffxiv_character = FFXIV::Character.for_lodestone_id(lodestone_data[:lodestone_id])

    @character_registration = CharacterRegistration.new(
      character: ffxiv_character,
      user: current_user,
      **character_registration_params
    )

    if lodestone_data[:region]
      @character_registration.extra_data[:region] = lodestone_data[:region]
    end

    respond_to do |format|
      if @character_registration.save
        format.html do
          redirect_to character_registrations_path, notice: "Character registration was successfully created."
        end
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /character_registrations/1 or /character_registrations/1.json
  def update
    authorize! :update, @character_registration

    respond_to do |format|
      if @character_registration.update(character_registration_params)
        format.html do
          redirect_to character_registrations_path, notice: "Character registration was successfully updated."
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /character_registrations/1 or /character_registrations/1.json
  def destroy
    authorize! :destroy, @character_registration

    @character_registration.destroy

    respond_to do |format|
      format.html do
        redirect_to character_registrations_path, notice: "Character registration was successfully destroyed."
      end
      format.turbo_stream do
        # handled in the model now...
      end
    end
  end

  def refresh
    @character_registration = CharacterRegistration.find(params[:character_registration_id])
    authorize! :update, @character_registration

    unless @character_registration.character.stale?
      respond_to do |format|
        format.html { redirect_to character_registrations_path, alert: "Character is not yet stale!" }
      end

      return
    end

    if FFXIV::RefreshCharactersJob.perform_later @character_registration.character
      respond_to do |format|
        format.html { redirect_to character_registrations_path, notice: "Character refresh was successfully enqueued." }
      end
    else
      respond_to do |format|
        format.html { redirect_to character_registrations_path, error: "Character refresh could not be enqueued." }
      end
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  private def set_character_registration
    @character_registration = CharacterRegistration.find(params[:id])
    raise ActiveRecord::RecordNotFound unless can? :show, @character_registration

    @character = @character_registration.character
  end

  # Only allow a list of trusted parameters through.
  private def character_registration_params
    params.require(:character_registration)
          .permit(:character_key)
  end

  private def render_new_form_again(status: :unprocessable_entity)
    render status: status,
           turbo_stream: turbo_stream.update("register_character_modal-content",
                                             partial: "portal/characters/partials/new_character_form")
  end
end
