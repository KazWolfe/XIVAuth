# frozen_string_literal: true

class Admin::CharactersController < Admin::AdminController
  before_action :set_character, only: %i[show update destroy]

  def index
    @characters = FFXIV::Character.order(created_at: :desc)
  end

  def show
    @verified_registration = @character.character_registrations.verified.first
  end

  def destroy
    if @user.destroy
      redirect_to admin_character_path, notice: 'Character deleted.'
    else
      redirect_to admin_character_path(@character), alert: 'Character could not be deleted.'
    end
  end

  private

  def set_character
    @character = FFXIV::Character.find_by_lodestone_id(params[:lodestone_id])
  end
end
