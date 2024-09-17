class OAuth::PermissibleRule < ApplicationRecord
  belongs_to :policy, class_name: "OAuth::PermissiblePolicy"
  belongs_to :resource, polymorphic: true
end
