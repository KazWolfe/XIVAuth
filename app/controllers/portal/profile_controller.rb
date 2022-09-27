class Portal::ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @external_identities = current_user.external_identities
  end

  def update
    @user = current_user
    filtered_params = params.require(:user).permit(%i[username email])

    @user.update(filtered_params)
  end
  
  def destroy
    @user = current_user
    
    # no-op for now
  end

  def password_modal
    @user = current_user
  end

  def update_password
    @user = current_user
    filtered_params = params.require(:user).permit(%i[current_password password password_confirmation])

    updated = current_user.update_with_password(filtered_params)

    if updated
      bypass_sign_in @user
      redirect_to profile_path
    else
      current_user.clean_up_passwords
      render turbo_stream: turbo_stream.update('remote_modal-content', partial: 'portal/profile/partials/password_form'),
             status: :unprocessable_entity
    end
  end

  def destroy_external_identity
    external_identity = Users::ExternalIdentity.find(params[:id])
    external_identity.destroy!

    redirect_to profile_path
  end
end
