class Users::SocialIdentitiesController < ApplicationController
  before_action :load_identity

  def destroy
    authorize! :destroy, @identity

    @identity.destroy

    redirect_to edit_user_registration_path, notice: "Identity was removed."
  end

  private def load_identity
    @identity = Users::SocialIdentity.find(params[:id])
    authorize! :show, @identity
  end
end
