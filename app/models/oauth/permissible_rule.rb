class OAuth::PermissibleRule < ApplicationRecord
  belongs_to :policy, class_name: "OAuth::PermissiblePolicy"
  belongs_to :resource, polymorphic: true, optional: true

  # Checks if this rule points at the special "null record," used for evaluation purposes.
  def null_record?
    self.resource_id.nil?
  end
end
