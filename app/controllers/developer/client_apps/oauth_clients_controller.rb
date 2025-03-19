class Developer::ClientApps::OAuthClientsController < ApplicationController
  before_action :set_oauth_client

  def show; end

  def update
    authorize! :edit, @application

    updates = filtered_params
    updates[:redirect_uris] = updates[:redirect_uris].compact_blank

    @oauth_client.update(updates)

    if @oauth_client.save
      respond_to do |format|
        format.html { redirect_to developer_oauth_client_path(@oauth_client), notice: "Updated." }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = "Update failed."
          redirect_back fallback_location: developer_oauth_client_path(@oauth_client)
        end
      end
    end
  end

  def regenerate
    authorize! :edit, @application

    @oauth_client.renew_secret

    if @oauth_client.save
      flash[:application_secret] = @oauth_client.plaintext_secret

      respond_to do |format|
        format.html { redirect_to developer_oauth_client_path(@application), notice: "Secret regenerated!" }
        format.json { render json: @oauth_client, as_owner: true }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to developer_application_path(@application),
                      status: :unprocessable_entity,
                      error: "Could not regenerate app secret."
        end
        format.json { render json: @oauth_client, as_owner: true }
      end
    end
  end

  private def set_oauth_client
    @oauth_client = ClientApplication::OAuthClient.find(params[:id])
    @application = @oauth_client.application

    raise ActiveRecord::RecordNotFound unless can? :show, @application
  end

  private def filtered_params
    params.require(:oauth_client).permit(:name, :enabled, :expires_at, redirect_uris: [])
  end
end
