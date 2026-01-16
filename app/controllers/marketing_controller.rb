class MarketingController < ApplicationController
  skip_before_action :authenticate_user!
  layout "marketing/base"

  def index; end

  def flarestone; end

  def discord
    redirect_to "https://discord.com/invite/nFPPTcDDgH", allow_other_host: true
  end
end
