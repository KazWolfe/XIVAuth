class CharacterRegistrationsController < ApplicationController
  before_action :set_character_registration, only: %i[ show destroy ]

  # GET /character_registrations or /character_registrations.json
  def index
    @character_registrations = CharacterRegistration.accessible_by(current_ability)
  end

  # GET /character_registrations/new
  def new
    @character_registration = CharacterRegistration.new
  end

  # POST /character_registrations or /character_registrations.json
  def create
    lodestone_id = helpers.extract_id(character_registration_params[:lodestone_url])
    ffxiv_character = FFXIV::Character.for_lodestone_id(lodestone_id)

    @character_registration = CharacterRegistration.new(character: ffxiv_character, user: current_user)

    respond_to do |format|
      if @character_registration.save
        format.html { redirect_to character_registrations_path, notice: "Character registration was successfully created." }
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
        format.html { redirect_to character_registrations_path, notice: "Character registration was successfully updated." }
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
      format.html { redirect_to character_registrations_path, notice: "Character registration was successfully destroyed." }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_character_registration
    @character_registration = CharacterRegistration.find(params[:id])
    authorize! :show, @character_registration
    
    @character = @character_registration.character
  end

  # Only allow a list of trusted parameters through.
  def character_registration_params
    params.fetch(:character_registration, {})
  end
end
