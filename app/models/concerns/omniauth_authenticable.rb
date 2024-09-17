module OmniauthAuthenticable
  extend ActiveSupport::Concern

  included do
    # @param [OmniAuth::AuthHash] data
    def add_social_identity(data)
      # TODO: Discord specifically is weird and doesn't map username to nickname properly. This may need to be fixed
      #       depending on how badly certain clients behave. (Please guys, use IDs.)

      identity = {
        provider: data["provider"],
        external_id: data["uid"],
        email: data["info"]["email"],
        name: data["info"]["name"],
        nickname: data["info"]["nickname"],
        raw_info: data["extra"]["raw_info"]
      }

      social_identities.build(identity)
    end
  end

  class_methods do
    def new_with_omniauth(auth)
      user = User.new(
        email: auth.dig(:info, :email),
        password: nil,
        profile_attributes: {
          display_name: auth.dig(:info, :nickname) || auth.dig(:info, :name)
        }
      )

      user.add_social_identity(auth)
      user.skip_confirmation!

      user
    end

    def new_with_session(params, session)
      super.tap do |user|
        if (data = session["devise.oauth.data"])
          user.email = data["info"]["email"] if user.email.blank?
          user.add_social_identity(data)
        end
      end
    end
  end
end
