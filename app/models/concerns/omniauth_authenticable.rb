# frozen_string_literal: true

module OmniauthAuthenticable
  extend ActiveSupport::Concern

  included do
    # @param [OmniAuth::AuthHash] data
    def add_social_identity(data)
      # TODO: Discord specifically is weird and doesn't map username to nickname properly. This may need to be fixed
      #       depending on how badly certain clients behave. (Please guys, use IDs.)

      identity = {
        provider: data['provider'],
        external_id: data['uid'],
        email: data['info']['email'],
        name: data['info']['name'],
        nickname: data['info']['nickname'],
        raw_info: data['extra']['raw_info']
      }

      social_identities.build(identity)
    end
  end

  class_methods do
    # @param [OmniAuth::AuthHash] auth
    # @return [User, nil]
    def find_by_omniauth(auth)
      social_identity = SocialIdentity.find_by(provider: auth.provider, external_id: auth.uid)
      if social_identity.present?
        social_identity.merge_auth_hash(auth)
        return social_identity.user
      end

      email = auth.dig(:info, :email)
      return nil unless email.present?

      existing_user = find_for_database_authentication(email: email.downcase)
      if existing_user
        existing_user.add_social_identity(auth)
      end

      # returns nil if none found
      return existing_user
    end

    def new_with_omniauth(auth)
      user = User.new(
        email: auth.dig(:info, :email),
        password: Devise.friendly_token
      )

      user.add_social_identity(auth)
      user.skip_confirmation!

      user
    end

    def new_with_session(params, session)
      super.tap do |user|
        if (data = session['devise.oauth.data'])
          user.email = data['info']['email'] if user.email.blank?
          user.add_social_identity(data)
        end
      end
    end
  end
end
