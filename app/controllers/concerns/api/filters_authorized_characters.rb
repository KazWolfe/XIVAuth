module Api::FiltersAuthorizedCharacters
  extend ActiveSupport::Concern

  # Load character registrations that are authorized for the current OAuth token,
  # considering both CanCan abilities and permissible policies.
  #
  # @return [ActiveRecord::Relation<CharacterRegistration>] Authorized character registrations
  def authorized_character_registrations(only_verified: false)
    # Return empty set if no character scope is present
    return CharacterRegistration.none unless has_character_scope?

    registrations = CharacterRegistration.accessible_by(current_ability)

    # If the token has character:manage scope, grant full access to all user's characters
    # Note: check only_verified here to avoid double-filtering after the chain.
    return registrations if has_character_manage_scope? && !only_verified
    return registrations.verified if has_character_manage_scope? && only_verified

    # Otherwise, filter to verified characters only
    registrations = registrations.verified

    # Apply permissible policy restrictions if present
    policy = doorkeeper_token.permissible_policy
    if policy.present?
      # Filter in-memory, then convert back to a relation to maintain chainability
      authorized_ids = registrations.select { |r| policy.can_access_resource?(r) }.map(&:id)
      registrations = CharacterRegistration.where(id: authorized_ids)
    elsif !has_bulk_character_scope?
      # Default-deny `character` scope if there's no policy (somehow)
      # Note: character:all without a policy does request *all* characters, so this is just pure character.
      return CharacterRegistration.none
    end

    registrations
  end

  # Check if the current OAuth token has the character:manage scope
  #
  # @return [Boolean] true if character:manage scope is present
  def has_character_manage_scope?
    doorkeeper_token.scopes.include?("character:manage")
  end

  # Check if the current OAuth token has any character scope
  #
  # @return [Boolean] true if any character scope is present
  def has_character_scope?
    doorkeeper_token.scopes.exists?("character") ||
      doorkeeper_token.scopes.exists?("character:all") ||
      doorkeeper_token.scopes.exists?("character:manage") ||
      doorkeeper_token.scopes.exists?("character:jwt")
  end

  def has_bulk_character_scope?
    doorkeeper_token.scopes.exists?("character:all") ||
      doorkeeper_token.scopes.exists?("character:manage")
  end
end

