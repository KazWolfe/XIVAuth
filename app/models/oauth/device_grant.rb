class OAuth::DeviceGrant < ApplicationRecord
  include ::Doorkeeper::DeviceAuthorizationGrant::Orm::ActiveRecord::Mixins::DeviceGrant

  belongs_to :permissible_policy, class_name: "OAuth::PermissiblePolicy", optional: true
end