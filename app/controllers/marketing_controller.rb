class MarketingController < ApplicationController
  def index
    @current_time = DateTime.now
  end
end
