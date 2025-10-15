require 'semantic_logger'

# frozen_string_literal: true
module ContextualLogger
  module Formatters
    class ColorFormatter < ::SemanticLogger::Formatters::Color

      def named_tags
        named_tags = log.named_tags.clone
        named_tags.delete(:_mdc)
        return if named_tags.nil? || named_tags.empty?

        list = []
        named_tags.each_pair { |name, value| list << "#{name}: #{value}" }
        "{#{list.join(', ')}}"
      end
    end
  end
end
