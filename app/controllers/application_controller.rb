class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_gon_context
  before_action :set_sentry_context

  before_action :redirect_to_new_domain

  private def set_sentry_context
    return unless user_signed_in?
    Sentry.set_user(id: current_user.id)
  end

  private def set_gon_context
    if user_signed_in?
      gon.push({ user: { id: current_user.id, email: current_user.email, name: current_user.display_name } })
    end

    gon.push({ env: ENV["APP_ENV"] || Rails.env })
  end

  private def redirect_to_new_domain
    if request.host == "edge.xivauth.net" || request.host == "www.xivauth.net"
      redirect_to "#{request.protocol}xivauth.net#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end

    if request.host == "eorzea.id"
      redirect_to "#{request.protocol}xivauth.net", status: :found, allow_other_host: true
    end
  end
end
