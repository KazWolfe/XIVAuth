class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    respond_to do |format|
      format.html { render }
      format.json { render json: { status: "ok" } }
    end
  end
end
