module OAuth::GrantValidators::IncompatibleScopes
  INCOMPATIBLE_SCOPES = [
    %w[character character:all]
  ].freeze

  class IncompatibleScopeError < StandardError; end

  # Check if the scopes provided are compatible with each other.
  # Does not check app-level compatibility, just policy.
  def self.find_incompatible_scopes(scopes)
    failures = []

    INCOMPATIBLE_SCOPES.each do |is|
      failures << is if Set.new(is).subset?(Set.new(scopes))
    end

    failures
  end

  def self.incompatible_scopes?(scopes)
    find_incompatible_scopes(scopes).any?
  end

  def self.validate_incompatible_scopes!(scopes)
    incompatible = find_incompatible_scopes(scopes)
    return if incompatible.empty?

    raise IncompatibleScopeError, "Incompatible scopes found: #{incompatible.map { |s| s.join(', ') }.join(' | ')}"
  end
end
