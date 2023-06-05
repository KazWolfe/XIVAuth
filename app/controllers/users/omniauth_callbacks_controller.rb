# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # FIXME: Possible security issue (?) - Steam doesn't give us CSRF back, so we have to deal with a bit of a headache.
  skip_before_action :verify_authenticity_token, only: [:steam]

  User.omniauth_providers.each do |provider|
    define_method(provider) do
      @provider = provider

      common
    end
  end

  private

  def common
    return sso_bind_identity if user_signed_in?

    unless User.omniauth_login_providers.include? @provider
      raise 'Cannot proceed with authentication for a non-login provider.'
    end

    sso_signin
  end

  def sso_signin
    raise 'sso_signin called while a user was logged in!' if user_signed_in?

    @user = find_user_by_authdata(auth_data)

    unless @user.present?
      unless User.omniauth_login_providers.include? @provider
        redirect_to new_user_session_path, alert: "#{@provider.to_s.titleize} accounts cannot be used for authentication."
        return
      end

      # check for login-only providers.
      if [:steam].include? @provider
        redirect_to new_user_session_path, alert: "#{@provider.to_s.titleize} must be linked before being used for " \
        "sign in. Please log in and link your #{@provider.to_s.titleize} account first."
        return
      end

      unless User.signup_permitted?
        redirect_to new_user_session_path, alert: 'Sign-ups are disabled at this time.'
        return
      end

      @user = User.new_with_omniauth(auth_data)
      @user.save
    end

    if @user.persisted?
      set_flash_message(:notice, :success, kind: auth_data['provider'].camelize) if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.oauth.data'] = auth_data.except(:extra)

      msg = @user.errors.full_messages.join("\n")
      redirect_to new_user_registration_url, alert: msg
    end
  end

  def sso_bind_identity
    identity = SocialIdentity.find_by(provider: auth_data[:provider], external_id: auth_data[:uid])
    if identity.present?
      if identity.user == current_user
        identity.merge_auth_hash(auth_data)

        redirect_to edit_user_registration_path, alert: 'This social identity already exists on your account! ' \
                                                        'Information about this identity has been updated.'
      else
        redirect_to edit_user_registration_path, alert: 'This social identity is already used on another account. ' \
                                                        'Please delete it from that account first.'
      end

      return
    end

    identity = current_user.add_social_identity(auth_data)

    if identity.save
      set_flash_message(:notice, :success, kind: auth_data['provider'].camelize) if is_navigational_format?
      redirect_to edit_user_registration_path
    else
      redirect_to edit_user_registration_path, alert: identity.errors.full_messages.join("\n")
    end
  end

  def auth_data
    request.env['omniauth.auth']
  end

  def find_user_by_authdata(auth)
    social_identity = SocialIdentity.find_by(provider: auth.provider, external_id: auth.uid)
    if social_identity.present?
      social_identity.merge_auth_hash(auth)
      social_identity.touch_used_at
      return social_identity.user
    end

    email = auth.dig(:info, :email)
    return nil unless email.present?

    existing_user = find_for_database_authentication(email: email.downcase)
    existing_user&.add_social_identity(auth)

    # returns nil if none found
    existing_user
  end
end
