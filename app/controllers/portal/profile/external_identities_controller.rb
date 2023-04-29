class Portal::Profile::ExternalIdentitiesController < ApplicationController
  def destroy
    external_identity = Users::ExternalIdentity.find(params[:id])
    external_identity.destroy!

    redirect_to profile_path
  end
end
