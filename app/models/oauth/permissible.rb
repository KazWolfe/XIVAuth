class OAuth::Permissible < ApplicationRecord
  belongs_to :oauth_access_grant, :class_name => 'OAuth::AccessGrant', primary_key: :permissible_id, optional: true
  belongs_to :oauth_access_token, :class_name => 'OAuth::AccessToken', primary_key: :permissible_id, optional: true

  belongs_to :resource, polymorphic: true

  scope :for_policy_id, ->(policy_id) { where(policy_id: policy_id) }

  def self.create_policy_for_resources(resources)
    policy_id = SecureRandom.uuid
    created_permissibles = []

    resources.each do |r|
      created_permissibles << OAuth::Permissible.create!(
        policy_id: policy_id,
        resource: r
      )
    end

    created_permissibles
  end
end
