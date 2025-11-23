class MarketingController < ApplicationController
  skip_before_action :authenticate_user!
  layout "marketing/base"

  def index; end

  def flarestone; end
end