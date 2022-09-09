class Oauth::Permissible < ApplicationRecord
  belongs_to :oauth_access_grant, :class_name => 'Oauth::AccessGrant', primary_key: :permissible_id, optional: true
  belongs_to :oauth_access_token, :class_name => 'Oauth::AccessToken', primary_key: :permissible_id, optional: true

  belongs_to :resource, polymorphic: true

  scope :for_policy_id, ->(policy_id) { where(policy_id: policy_id) }
end
