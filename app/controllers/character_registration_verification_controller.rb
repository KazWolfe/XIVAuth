class CharacterRegistrationVerificationController < ApplicationController
  before_action :set_character_registration

  def index
    respond_to do |format|
      if !@character_registration.verified?
        format.html { render 'character_registration_verification/create' }
        format.json { render json: { verification_key: @character_registration.verification_key }}
      else
        format.html { redirect_to character_registrations_path, error: 'This character is already verified!' }
        format.json { head :unprocessable_entity }
      end
    end
  end

  def create
    authorize! :update, @character_registration
    
    job = VerifyCharacterRegistrationJob.perform_later @character_registration

    respond_to do |format|
      if job
        format.html { redirect_to character_registrations_path, notice: 'Registration job enqueued.' }
        format.json { render json: { job_id: job.job_id }, status: :created }
      else
        format.html { redirect_to character_registrations_path, error: 'Could not enqueue job?' }
        format.json { head :internal_server_error }
      end
    end
  end

  def destroy
    authorize! :manage, @character_registration
    
    @character_registration.verified_at = nil

    respond_to do |format|
      if @character_registration.save
        format.html { redirect_to character_registrations_path, notice: 'Character was successfully unverified' }
        format.json { head :no_content }
      else
        format.html { redirect_to character_registrations_path, error: 'Could not unverify character.' }
        format.json { render json: @character_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_character_registration
    @character_registration = CharacterRegistration.find(params[:character_registration_id])
    authorize! :show, @character_registration
    
    @character = @character_registration.character
  end
end
