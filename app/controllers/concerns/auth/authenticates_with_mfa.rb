# High level logic borrowed from GitLab.
# https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/concerns/authenticates_with_two_factor.rb

module Auth::AuthenticatesWithMFA
  extend ActiveSupport::Concern

  def prompt_for_mfa(user)
    # Set for devise views
    @user = user

    session[:mfa_user_id] = user.id
  end

  def authenticate_with_mfa
    user = self.resource = find_user

    if user_params[:otp_attempt].present? && session[:mfa_user_id]
      authenticate_via_otp(user)
    elsif user_params[:devise_response].present? && session[:mfa_user_id]
      authenticate_via_webauthn(user)
    elsif user && user.valid_password?(user_params[:password])
      prompt_for_mfa(user)
    end
  end

  private

  def authenticate_via_otp(user)
    _
  end

  def authenticate_via_webauthn(user)
    _
  end

  def clear_two_factor_attempt!
    session.delete(:mfa_user_id)
  end
  
  def setup_webauthn_attempt(user)
    if user.webauthn_credentials.present?
      registration_ids = user.webauthn_credentials.pluck(:external_id)
    end
  end
end