class Admin::CharactersController < ApplicationController
  def index
    @characters = Character.accessible_by(current_ability)
  end

  def show
    @character = Character.find(params[:id])
  end
end
