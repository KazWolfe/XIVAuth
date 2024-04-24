# frozen_string_literal: true

module Users
  class Profile < ApplicationRecord
    belongs_to :user, class_name: 'User', touch: true

    # TODO: maybe this should be a database table...
    DISPLAY_NAME_BLOCKED_WORDS = [
      'auth', 'admin', 'root', 'system', 'oauth', 'security', 'dalamud', 'support', 'moderator',
      /ff[-._]*xiv/, /ff[-._]*14/, /square[-._]*enix/, 'squarenix', /yoshi[-._]?p/
    ].freeze

    validates :display_name, length: { in: 6..32 }, presence: true, uniqueness: { case_sensitive: false }
    validates :display_name, format: { with: /\A[a-zA-Z0-9._-]+\z/,
                                       message: 'only allows alphanumerics, underscores, periods, and dashes.' }
    validates :display_name, format: { without: /#{Regexp.union(DISPLAY_NAME_BLOCKED_WORDS).source}/i,
                                       message: 'cannot be used' }, if: :display_name_changed?
  end
end
