class Admin::AdminController < ApplicationController
  before_action :authorize_admin!

  def authorize_admin!
    # n.b. this should already be handled by the routing layer, but we'll put this here for safety's sake as well.
    raise ActionController::RoutingError, "Not Found" unless current_user.admin?
  end
end
