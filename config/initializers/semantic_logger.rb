require 'contextual_logger/middleware'
require 'contextual_logger/formatters/json_formatter'
require 'contextual_logger/formatters/color_formatter'

# default log formatter
Rails.application.middleware.insert_before RailsSemanticLogger::Rack::Logger, ContextualLogger::Middleware
