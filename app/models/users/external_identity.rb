class Users::ExternalIdentity < ApplicationRecord
  belongs_to :user, optional: true

  validates_uniqueness_of :external_id, scope: [:provider]
  validates_uniqueness_of :user_id, scope: [:provider]
end
