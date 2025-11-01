class ErrorsController < ActionController::Base
  helper ApplicationHelper
  before_action :set_trace_id
  layout "error"

  def show
    @exception = request.env["action_dispatch.exception"]

    @status_code = @exception.try(:status_code) ||
                   ActionDispatch::ExceptionWrapper.new(
                     request.env, @exception
                   ).status_code

    # Return a specific error page for any response, if it exists
    if template_exists? "errors/#{@status_code}"
      render "errors/#{@status_code}", status: @status_code
      return
    end

    # Fallback to a generic error page that matches the requested format, if it exists
    if template_exists? "errors/generic"
      render "errors/generic", status: @status_code, locals: { status: @status_code }
      return
    end

    # Fallback to a specific error page via HTML, if it exists
    if template_exists? "errors/#{@status_code}", formats: [:html]
      render "errors/#{@status_code}", status: @status_code, formats: [:html]
      return
    end

    # Fallback to a generic error page via HTML
    render "errors/generic", status: @status_code, locals: { status: @status_code }, formats: [:html]
  end

  private def set_trace_id
    trace = {
      "Event ID": (Sentry.last_event_id if defined?(Sentry)),
      "Trace ID": get_internal_trace_id,
      "Request ID": request.uuid # fallback
    }

    @trace_type, @trace_id = trace.select { |_, v| v.present? }.first
  end

  private def get_internal_trace_id
    return OpenTelemetry::Trace.current_span.context.hex_trace_id if defined?(OpenTelemetry)
    return Sentry.get_current_scope&.get_span&.trace_id if defined?(Sentry)

    nil
  end
end
