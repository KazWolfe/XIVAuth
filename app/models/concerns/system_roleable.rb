# frozen_string_literal: true

module SystemRoleable
  extend ActiveSupport::Concern
  
  included do
    def has_role?(role)
      roles.include? role
    end

    def add_role(role)
      self.roles += role
    end
  end
end
