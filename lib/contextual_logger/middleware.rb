require 'contextual_logger/log_context'

module ContextualLogger
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      LogContext.clear

      [status, headers, response]
    end
  end
end