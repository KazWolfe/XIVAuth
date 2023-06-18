class OAuth::PermissiblePolicy < ApplicationRecord
  has_many :entries, class_name: 'OAuth::PermissibleEntry', foreign_key: 'policy_id', dependent: :destroy

  # Determine if the specified resource can be accessed or not.
  # @param fallback [Boolean, nil] Specify a fallback behavior if an explicit rule was not found.
  def can_access_resource?(resource, fallback: nil)
    resource_rules = entries.where(resource:)

    return false if resource_rules.where(deny: true).count.positive?
    return true if resource_rules.where(deny: false).count.positive?

    return fallback unless fallback.nil?

    !implicit_deny?
  end

  # Check if implicit denial should be used for this policy.
  # Implicit deny will take effect if this policy has *any* explicit allow record associated with it.
  def implicit_deny?
    entries.where(deny: false).count.positive?
  end
end
