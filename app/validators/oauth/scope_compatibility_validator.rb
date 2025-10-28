class OAuth::ScopeCompatibilityValidator < ActiveModel::Validator
  INCOMPATIBLE_SCOPES = [
    %w[character character:all character:manage]
  ].freeze

  def validate(record)
    target_field = options[:target_field] || :base
    invalid_scopes = self.class.find_incompatible_scopes(record.scopes)

    invalid_scopes.each do |problem|
      record.errors.add(target_field, :incompatible_scopes,
                        message: "cannot request the following scopes together: #{problem.join(', ')}")
    end
  end

  def self.find_incompatible_scopes(scopes, exclusive_scopes = INCOMPATIBLE_SCOPES)
    failures = []

    exclusive_scopes.each do |exclusive|
      intersection = Set.new(scopes) & exclusive

      failures << intersection if intersection.size > 1
    end

    failures
  end

  def self.incompatible_scopes?(scopes)
    find_incompatible_scopes(scopes).any?
  end
end
