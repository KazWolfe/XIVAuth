class OAuth::PreAuthorization < Doorkeeper::OAuth::PreAuthorization
  # The fact that this works is *terrifying*. Ruby, please. PLEASE. DO NOT. NO. BAD.
  @validations = superclass.validations
  validate :scope_usability, error: :scope_invalid_for_resource_owner

  def validate_scope_usability
    # Guard - short-circuit if the resource owner has problems
    return true unless @resource_owner.present?

    # Verify character-related scopes
    if @resource_owner.respond_to?('characters')
      return false if scopes.include?('character') && !@resource_owner.characters.verified.count.positive?
      return false if scope == 'character:all' && !@resource_owner.characters.verified.count.positive?
    end

    true
  end
end
