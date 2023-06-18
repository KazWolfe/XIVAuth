class OAuth::PermissibleEntry < ApplicationRecord
  belongs_to :policy, class_name: 'OAuth::PermissiblePolicy', foreign_key: 'policy_id'
  belongs_to :resource, polymorphic: true
end
