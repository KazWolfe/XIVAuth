class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_sentry_context, if: proc { Rails.env.production? }

  private

  def set_sentry_context
    Sentry.set_user(id: current_user.id) if user_signed_in?
  end
end
