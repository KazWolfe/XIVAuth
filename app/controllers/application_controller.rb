class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_otel_context

  private def set_otel_context
    return unless current_user.present?

    OpenTelemetry::Trace.current_span.add_attributes({
      "user.id" => current_user.id
    })
  end
end
