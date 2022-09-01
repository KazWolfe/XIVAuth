class MarketingController < ApplicationController
  def index
    # Marketing only catches users who aren't logged in.
    redirect_to characters_path, status: :temporary_redirect unless current_user.nil?

    # just render directly for now, not too concerned.
  end
end
