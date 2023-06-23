class OAuth::PermissiblePolicy < ApplicationRecord
  has_many :rules, class_name: 'OAuth::PermissibleRule', foreign_key: 'policy_id', dependent: :destroy

  # Determine if the specified resource can be accessed or not.
  # @param fallback [Boolean, nil] Specify a fallback behavior if an explicit rule was not found.
  def can_access_resource?(resource, fallback: nil)
    resource_rules = rules.where(resource:)

    return false if resource_rules.where(deny: true).count.positive?
    return true if resource_rules.where(deny: false).count.positive?

    return fallback unless fallback.nil?

    !implicit_deny?(resource_type: resource.class.polymorphic_name)
  end

  # Check if implicit denial should be used for this policy. The policy will use implicit denial if *any* rule in the
  # policy is set to explicit allow (deny = false).
  # @param resource_type [String, nil] When set, limit evaluation to this specific type. Used for mixed-resource policies.
  # @return [Boolean] Returns true if implicit-deny mode should be used.
  def implicit_deny?(resource_type: nil)
    search = { deny: false }
    search[:resource_type] = resource_type if resource_type.present?

    rules.where(search).count.positive?
  end
end
