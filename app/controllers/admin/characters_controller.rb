# frozen_string_literal: true

class Admin::CharactersController < Admin::AdminController
  before_action :set_character, only: %i[ show update destroy refresh ]

  def index
    @characters = FFXIV::Character.order(created_at: :desc)
  end

  def show
    @verified_registration = @character.character_registrations.verified.first
  end

  def destroy
    if @character.destroy
      redirect_to admin_characters_path, notice: 'Character deleted.'
    else
      redirect_to admin_character_path(@character), alert: 'Character could not be deleted.'
    end
  end

  def refresh
    if FFXIV::RefreshCharactersJob.perform_later(@character, force_refresh: true)
      respond_to do |format|
        format.html { redirect_to admin_character_path(@character.lodestone_id), notice: 'Character refresh was successfully enqueued.' }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_character_path(@character.lodestone_id), error: 'Character refresh could not be enqueued.' }
      end
    end
  end

  private

  def set_character
    @character = FFXIV::Character.find_by_lodestone_id(params[:lodestone_id])
  end
end
