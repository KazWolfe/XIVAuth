class MarketingController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  layout "marketing/base"

  def index
    @current_time = DateTime.now
  end
end