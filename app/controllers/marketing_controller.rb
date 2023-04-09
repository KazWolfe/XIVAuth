class MarketingController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  def index
    @current_time = DateTime.now
  end
end
