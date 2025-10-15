class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_observability_context

  before_action :redirect_to_new_domain

  private def set_observability_context
    sentry_frontend_data = {
      environment: ENV["APP_ENV"] || Rails.env,
      dsn: Rails.application.credentials.dig(:sentry, :dsn) || "https://d26e06e98289421f9eb53d5d892ab660@o4505361640325120.ingest.us.sentry.io/4505361641504768",
      user: nil
    }

    if user_signed_in?
      sentry_frontend_data[:user] = {
        id: current_user.id,
        feedback_email: current_user.email,
        username: current_user.display_name
      }

      Sentry.set_user(id: current_user.id, username: current_user.display_name)
      LogContext.add(user: { id: current_user.id, username: current_user.display_name })
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
