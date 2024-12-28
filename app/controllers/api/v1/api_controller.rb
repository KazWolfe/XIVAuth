class Api::V1::ApiController < ActionController::API
  # There are no "open" API calls; everything must require at least authorization.
  before_action :doorkeeper_authorize!
  before_action :load_token
  before_action :set_otel_context

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

  private def set_otel_context
    return unless doorkeeper_token
    
    attrs = {
      "oauth.application_id": doorkeeper_token.application_id,
      "oauth.scopes": doorkeeper_token.scopes
    }

    attrs["user.id"] = current_user.id if current_user.present?

    OpenTelemetry::Trace.current_span.add_attributes(attrs)
  end
end
