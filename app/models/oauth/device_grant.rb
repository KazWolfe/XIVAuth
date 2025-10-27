class OAuth::DeviceGrant < ApplicationRecord
  include ::Doorkeeper::DeviceAuthorizationGrant::DeviceGrantMixin

  belongs_to :permissible_policy, class_name: "OAuth::PermissiblePolicy", optional: true
end