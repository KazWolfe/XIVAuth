class OAuth::PreAuthorization < Doorkeeper::OAuth::PreAuthorization
  # The fact that this works is *terrifying*. Ruby, please. PLEASE. DO NOT. NO. BAD.
  @validations = superclass.validations
  validate :scope_usability, error: :scope_invalid_for_resource_owner

  def validate_scope_usability
    # Guard - short-circuit if the resource owner has problems
    return true unless @resource_owner.present?

    # Verify character-related scopes
    if @resource_owner.respond_to?('characters')
      if scopes.include?('character') || scope == 'character:all'
        # Hack to display a more specific error, this'll still end validation early,
        # but with a different and more descriptive message.
        @error = :no_verified_characters unless @resource_owner.characters.verified.count.positive?
      end
    end

    true
  end
end
