class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'error'

  def show
    @exception = request.env['action_dispatch.exception']
    @trace_id = trace_id
    
    @status_code = @exception.try(:status_code) ||
      ActionDispatch::ExceptionWrapper.new(
        request.env, @exception
      ).status_code

    render 'errors/generic', status: @status_code and return unless template_exists? "errors/#{@status_code}"

    render template: "errors/#{@status_code}", status: @status_code
  end

  private

  def trace_id
    Sentry.get_current_scope&.get_span&.trace_id ||
      Sentry.get_current_scope&.propagation_context&.trace_id ||
      request.uuid
  end
end
