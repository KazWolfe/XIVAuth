class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_sentry_context, if: proc { Rails.env.production? }

  before_action :redirect_to_new_domain

  private def set_sentry_context
    Sentry.set_user(id: current_user.id) if user_signed_in?
  end

  private def redirect_to_new_domain
    if request.host == "edge.xivauth.net"
      redirect_to "#{request.protocol}xivauth.net#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end

    if request.host == "eorzea.id"
      redirect_to "#{request.protocol}xivauth.net", status: :moved_temporarily, allow_other_host: true
    end
  end
end
