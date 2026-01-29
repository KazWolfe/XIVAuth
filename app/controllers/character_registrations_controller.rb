class CharacterRegistrationsController < ApplicationController
  include Pagy::Method

  layout "portal/page"
  before_action :set_character_registration, only: %i[show destroy]

  # GET /character_registrations or /character_registrations.json
  def index
    @pagy, @character_registrations = pagy(CharacterRegistration.where(user: current_user), items: 12)

    render :index, layout: "portal/base"
  end

  # GET /character_registrations/new
  def new
    @character_registration = CharacterRegistrationRequest.new
  end

  # POST /character_registrations or /character_registrations.json
  def create
    @character_registration = CharacterRegistrationRequest.new(character_registration_params.merge(user: current_user))

    case @character_registration.process!
    when :success
      respond_to do |format|
        format.html do
          redirect_to character_registrations_path,
                      notice: "Character registration was successfully created."
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("register_character_modal-content",
                                                   partial: "layouts/components/remote_modal_close")
        end
      end

      record_create_analytics(@character_registration.created_character)
    when :confirm
      respond_to do |format|
        format.html { render :confirm }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "register_character_modal-content",
            partial: "character_registrations/confirm",
            locals: { candidates: @character_registration.candidates, name: @character_registration.search_name, world: @character_registration.search_world }
          )
        end
      end
    else
      render_new_form_again
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
        format.html { render :edit, status: :unprocessable_content }
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
    @character_registration = current_user.character_registrations.find(params[:character_registration_id])
    authorize! :update, @character_registration

    unless @character_registration.character.stale?
      respond_to do |format|
        format.html { redirect_to character_registrations_path, alert: "Character is not yet stale!" }
      end

      return
    end

    FFXIV::RefreshCharactersJob.perform_later @character_registration.character

    respond_to do |format|
      format.html { redirect_to character_registrations_path, notice: "Character refresh was successfully enqueued." }
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
          .permit(:lodestone_url, :search_name, :search_world, :search_exact, :from_search)
  end

  private def render_new_form_again(status: :unprocessable_content)
    render status: status,
           turbo_stream: turbo_stream.update("register_character_modal-content",
                                             partial: "character_registrations/registration_form_modal",
                                             locals: { character_registration: @character_registration })
  end

  private def record_create_analytics(registration)
    if registration.nil?
      logger.warn("Attempted to record analytics for a failed registration. Wut?")
      return
    end

    analytics_type = if character_registration_params[:from_search].present?
                       :search_result
                     elsif character_registration_params[:search_name].present?
                       if character_registration_params[:search_exact] == "1"
                         :name_search_exact
                       else
                         :name_search
                       end
                     else
                       :lodestone_id
                     end

    Sentry.metrics.count(
      "xivauth.character.register",
      value: 1,
      attributes: {
        "registration.search_type": analytics_type.to_s,
        "registration.is_first": (registration.character.character_registrations.count <= 1),

        "character.lodestone_id": registration.character.lodestone_id,
        "character.home_world": registration.character.home_world,
        "character.data_center": registration.character.data_center,

        # FIXME(DEPS): https://github.com/getsentry/sentry-ruby/issues/2842
        "user.id": current_user.id,
      }
    )
  end
end
