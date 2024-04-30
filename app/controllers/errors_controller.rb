class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_trace_id

  layout 'error'

  def show
    @exception = request.env['action_dispatch.exception']

    @status_code = @exception.try(:status_code) ||
      ActionDispatch::ExceptionWrapper.new(
        request.env, @exception
      ).status_code

    render 'errors/generic', status: @status_code and return unless template_exists? "errors/#{@status_code}"

    render template: "errors/#{@status_code}", status: @status_code
  end

  private

  def set_trace_id
    trace = {
      "Event ID": Sentry.last_event_id,
      "Trace ID": Sentry.get_current_scope&.get_span&.trace_id,
      "Request ID": request.uuid  # fallback
    }

    @trace_type, @trace_id = trace.select { |_, v| v.present? }.first
  end
end
