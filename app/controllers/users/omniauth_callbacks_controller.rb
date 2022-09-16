class Users::OmniauthCallbacksController < ApplicationController
  # Huge credit to
  # https://www.cyrusstoller.com/2019/09/17/supporting-multiple-omniauth-providers-with-devise

  def discord
    received_data = auth_data

    # load discord email verification
    received_data['info']['email_verified'] = received_data['extra']['raw_info']['verified']

    @user = User.from_omniauth(received_data)

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Discord'
      sign_in_and_redirect @user, event: :authentication
    else
      data = received_data.except('extra')

      session['devise.oauth.data'] = data
      msg = @user.errors.full_messages.join("\n")
      redirect_to new_user_registration_url, alert: msg
    end
  end

  def github
    received_data = auth_data

    # load github email verification info
    received_data['info']['email_verified'] = false
    received_data['extra']['all_emails'].each do |em|
      next unless em['email'].downcase == received_data['info']['email']

      received_data['info']['email_verified'] = em['verified']
      break
    end

    @user = User.from_omniauth(received_data)

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      data = received_data.except('extra')

      session['devise.oauth.data'] = data
      msg = @user.errors.full_messages.join("\n")
      redirect_to new_user_registration_url, alert: msg
    end
  end

  def steam

  end

  private

  def auth_data
    data = request.env['omniauth.auth']

    # overload field because we need it in a couple places.
    data['info']['email_verified'] = nil

    data
  end
end
