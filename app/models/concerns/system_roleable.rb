module SystemRoleable
  extend ActiveSupport::Concern

  APP_ROLES = %w[admin developer].freeze

  included do
    validates :roles, array: { presence: true, inclusion: { in: APP_ROLES } }

    def has_role?(role)
      return false if roles.blank?

      roles.include? role.to_s
    end

    def add_role(role)
      self.roles ||= []
      self.roles << role.to_s
    end
  end
end
