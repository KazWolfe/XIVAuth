class OAuth::CharacterOwnershipValidator < ActiveModel::Validator
  def validate(record)
    target_field = options[:target_field] || :base

    return if record.user.blank?
    return unless record.user.respond_to?(:character_registrations)

    return unless record.scopes.include?("character") || record.scopes == ["character:all"]
    return unless record.user.character_registrations.verified.empty?

    record.errors.add(target_field, :no_characters)
  end
end
