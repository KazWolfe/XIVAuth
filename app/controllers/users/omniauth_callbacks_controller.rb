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

  def auth_data
    request.env['omniauth.auth']
  end
end
