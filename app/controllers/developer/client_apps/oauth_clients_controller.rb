class Developer::ClientApps::OAuthClientsController < ApplicationController
  helper Developer::ClientApps::OAuthClientHelper
  layout "portal/page"

  before_action :set_oauth_client, except: [:new, :create]

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

  def new
    @application = ClientApplication.find(params[:application_id])
    @oauth_client = ClientApplication::OAuthClient.new
  end

  def create
    @application = ClientApplication.find(params[:application_id])
    authorize! :edit, @application

    @oauth_client = ClientApplication::OAuthClient.new(filtered_params)
    @oauth_client.application = @application

    if @oauth_client.save
      flash[:notice] = "OAuth client created successfully."
      redirect_to developer_oauth_client_path(@oauth_client)
    else
      flash.now[:error] = "Could not create OAuth client."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :edit, @application

    if @oauth_client.destroy
      respond_to do |format|
        format.html { redirect_to developer_application_path(@application), notice: "OAuth client deleted." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to developer_oauth_client_path(@oauth_client),
                      status: :unprocessable_entity,
                      error: "Could not delete OAuth client."
        end
        format.json { render json: { error: "Could not delete OAuth client." }, status: :unprocessable_entity }
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
    params.require(:oauth_client).permit(:name, :enabled, :expires_at, :confidential, :app_type,
                                         redirect_uris: [], grant_flows: [], scopes: [])
  end
end
