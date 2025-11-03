class OAuth::AccessGrant < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant
  include OAuth::ScopesAsArray

  belongs_to :permissible_policy, class_name: "OAuth::PermissiblePolicy", optional: true
end
