class Admin::CharacterRegistrationsController < Admin::AdminController
  before_action :set_context, only: %i[ show update destroy verify unverify ]

  def verify
    return if @character.verified?

    @registration.verify!(:administrative, clobber: params[:clobber] == true) and return if params[:force]

    FFXIV::VerifyCharacterRegistrationJob.perform_later @registration
  end

  def unverify
    return unless @registration.verified?

    @registration.unverify
    @registration.save
  end

  def destroy
    @registration.destroy
  end

  def set_context
    @registration = CharacterRegistration.find(params[:id])

    @character = @registration.character
    @user = @registration.user
  end
end
