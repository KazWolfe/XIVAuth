class Portal::CharactersController < ApplicationController
  before_action :authenticate_user!
  respond_to :html, :json

  def index
    @characters = current_user.characters.order(:verified_at)

    respond_with(@characters)
  end

  def show
    @character = Character.find(params[:id])
    authorize! :show, @character

    respond_with(@character)
  end
  
  def new
    @character = Character.new
  end
  
  def create
    lodestone_id = helpers.extract_id(params[:character][:lodestone_url])
    if lodestone_id.nil?
      render :new, status: :unprocessable_entity and return
    end

    @character = Character.new(
      :lodestone_id => lodestone_id,
      :user_id => current_user.id
    )

    @character.retrieve_from_lodestone!

    if @character.save!
      redirect_to characters_path, status: :created
    else
      render :new, status: :unprocessable_entity
    end
  end

  def verify
    @character = Character.find(params[:id])
    authorize! :verify, @character

    respond_with @character
  end

  def enqueue_verify
    @character = Character.find(params[:id])
    authorize! :verify, @character

    Character::VerifyCharacterJob.perform_later @character

    respond_with @character
  end

  def destroy
    @character = Character.find(params[:id])
    authorize! :destroy, @character
    @character.destroy

    redirect_to characters_path, status: :see_other
  end
end
