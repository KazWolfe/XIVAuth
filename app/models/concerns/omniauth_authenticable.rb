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
    def from_omniauth(auth)
      # ONLY USE THIS FOR AUTHENTICATION.
      raise 'from_omniauth called while a user was logged in! THIS IS A SECURITY CONCERN!' if current_user.present?

      social_identity = SocialIdentity.find_by(provider: auth.provider, external_id: auth.uid)
      if social_identity.present?
        social_identity.merge_auth_hash(auth)
        return social_identity.user
      end

      email = auth['info']['email']

      throw StandardError('No email defined! Was it verified?') unless email.present?

      existing_user = find_for_database_authentication(email: email.downcase)
      if existing_user
        existing_user.add_social_identity(auth).save
        return existing_user
      end

      create_new_user_from_oauth(auth, email)
    end

    def new_with_session(params, session)
      super.tap do |user|
        if (data = session['devise.oauth.data'])
          user.email = data['info']['email'] if user.email.blank?
          user.add_social_identity(data)
        end
      end
    end

    private

    def create_new_user_from_oauth(auth, email)
      attributes = {
        email: email,
        password: Devise.friendly_token
      }

      user = User.new(attributes)
      user.add_social_identity(auth)
      user.skip_confirmation!
      user.save

      user
    end

  end
end
