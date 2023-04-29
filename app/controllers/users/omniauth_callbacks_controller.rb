# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def discord
    common
  end

  def github
    common
  end

  def steam
    common
  end

  private

  def common
    return sso_link if current_user.present?

    sso_signin
  end

  def sso_signin
    @user = User.from_omniauth(auth_data)

    if @user.persisted?
      set_flash_message(:notice, :success, kind: auth_data['provider'].camelize) if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.oauth.data'] = auth_data.except(:extra)

      msg = @user.errors.full_messages.join("\n")
      redirect_to new_user_registration_url, alert: msg
    end
  end

  def sso_link
    identity = SocialIdentity.find_by(provider: auth_data[:provider], external_id: auth_data[:uid])
    if identity.present?
      if identity.user == current_user
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
end
