class Admin::CharactersController < ApplicationController
  def index
    @characters = Character.accessible_by(current_ability)
  end

  def show
    @character = Character.find(params[:id])

    # we want to be able to (relatively) quickly find other registrations for the same character. pass this over to the
    # view so that we can list them (should they exist)
    @same_lodestone = Character.where(lodestone_id: @character.lodestone_id)
                               .where.not(user: @character.user)
                               .order(:verified_at)
  end

  def destroy
    @character = Character.find(params[:id])

    Rails.logger.info "Destroying character #{@character.id} by administrative request", @character
    @character.destroy!
  end

  def update
    @character = Character.find(params[:id])

    case params[:command]
    when 'sync'
      Character::SyncLodestoneJob.perform_later @character
      redirect_to admin_character_path(@character) and return
    when 'unverify'
      @character.verified_at = nil
    when 'verify'
      command_safe_verify(@character)
    else
      return
    end

    @character.save!
    redirect_to admin_character_path(@character)
  end

  private

  def command_safe_verify(character)
    return 'Character already verified!' if Character.any_verified?(character.lodestone_id)

    character.verify!
  end
end
