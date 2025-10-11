class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_sentry_context, if: Rails.env.production?

  before_action :redirect_to_new_domain

  private def set_sentry_context
    sentry_frontend_data = {
      environment: ENV["APP_ENV"] || Rails.env,
      dsn: Sentry.configuration.dsn,
      user: nil
    }

    if user_signed_in?
      sentry_frontend_data[:user] = {
        id: current_user.id,
        email: current_user.email,
        name: current_user.display_name
      }

      Sentry.set_user(id: current_user.id) if user_signed_in?
    end

    gon.push({ sentry: sentry_frontend_data })
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
