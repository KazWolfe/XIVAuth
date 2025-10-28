# frozen_string_literal: true
require 'utilities/crockford'

module OAuth
  class CrockfordCodeGenerator
    def self.generate
      Crockford.generate(length: 8)
    end
  end
end
