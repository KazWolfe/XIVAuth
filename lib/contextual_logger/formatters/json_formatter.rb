require 'semantic_logger'

module ContextualLogger
  module Formatters
    class JsonFormatter < SemanticLogger::Formatters::Json
      def named_tags
        cloned_tags = log.named_tags.clone
        mdc_data = cloned_tags&.delete(:_mdc)

        self.hash[:named_tags] = cloned_tags if cloned_tags && !cloned_tags.empty?
        self.hash[:context] = mdc_data if mdc_data
      end
    end
  end
end