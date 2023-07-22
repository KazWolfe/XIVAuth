# frozen_string_literal: true

module OAuth
  class AuthorizationsController < Doorkeeper::AuthorizationsController

    def create
      # Cheat to get around needing client-side JavaScript to submit a DELETE.
      # The actual DELETE method still works, so this is in addition to compliance, at least.
      (destroy and return) if params['disposition'] == 'deny'

      super

      token = @authorize_response.auth.token
      if token.respond_to? :permissible_policy
        policy = build_permissible_policy
        policy.save!

        token.permissible_policy = policy
        token.save!
      end
    end

    private

    def build_permissible_policy
      policy = OAuth::PermissiblePolicy.new

      build_character_policy_rules(policy)
      build_identity_policy_rules(policy)

      policy
    end

    def build_character_policy_rules(policy)
      character_ids = params[:characters] || []
      share_new_characters = params[:share_new_characters].present?

      objects = CharacterRegistration.verified
                                     .where(user_id: current_resource_owner.id)
                                     .includes(:character)

      if share_new_characters
        # Filter to only characters that were *not* selected, so we can deny access to them.
        objects = objects.where.not('character.lodestone_id': character_ids)
      else
        # Otherwise, filter to only selected characters.
        objects = objects.where('character.lodestone_id': character_ids)
      end

      Rails.logger.info("Creating rules for #{objects.count} characters.")

      objects.each do |character|
        # Remember: deny happens only to the inverse selection
        policy.rules.new(resource: character, deny: share_new_characters)
      end
    end

    def build_identity_policy_rules(policy)
      identity_ids = params[:social_identities] || []
      share_new_identities = params[:share_new_identities].present?

      objects = Users::SocialIdentity.where(user_id: current_resource_owner.id)

      if share_new_identities
        # Filter to only identities that were *not* selected, so we can deny access to them.
        objects = objects.where.not(id: identity_ids)
      else
        # Otherwise, filter to only selected characters.
        objects = objects.where(id: identity_ids)
      end

      Rails.logger.info("Creating rules for #{objects.count} identities.")

      objects.each do |identity|
        # Remember: deny happens only to the inverse selection
        policy.rules.new(resource: identity, deny: share_new_identities)
      end
    end
  end
end
