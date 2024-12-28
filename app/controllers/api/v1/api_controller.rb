class Api::V1::ApiController < ActionController::API
  # There are no "open" API calls; everything must require at least authorization.
  before_action :doorkeeper_authorize!
  before_action :load_token
  before_action :set_sentry_context, if: proc { Rails.env.production? }

  respond_to :json

  def current_user
    return unless doorkeeper_token[:resource_owner_type] == "User"

    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end

  private def check_resource_owner_presence
    render status: :unauthorized unless current_user.present? && current_user.persisted?
  end

  private def load_token
    @doorkeeper_token = doorkeeper_token
  end

  private def set_sentry_context
    return unless doorkeeper_token

    ctx = {
      application_id: doorkeeper_token.application_id,
      scopes: doorkeeper_token.scopes
    }

    if current_user.present?
      Sentry.set_user(id: current_user.id)
      ctx[:user_id] = current_user.id
    end

    Sentry.set_context("oauth_application", ctx)
  end
end
