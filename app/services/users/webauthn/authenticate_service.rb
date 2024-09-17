class Users::Webauthn::AuthenticateService
  # Initialize a new instance of the webauthn sign-in validation service.
  # @param user [User] The XIVAuth user to authenticate
  # @param device_response [string] The response from the client/webauthn device to validate.
  # @param challenge The challenge from the session to validate against.
  def initialize(user, device_response, challenge)
    @user = user
    @device_response = device_response
    @challenge = challenge
  end

  def execute
    response_credential = WebAuthn::Credential.from_get(JSON.parse(@device_response))
    stored_credential = @user.webauthn_credentials.find_by(external_id: response_credential.id)

    response_credential.verify(@challenge, public_key: stored_credential.public_key,
sign_count: stored_credential.sign_count)

    stored_credential.update!(sign_count: response_credential.sign_count)
  end

  # Build a new Webauthn challenge for the specified user.
  # @param user [User] The user.
  # @return Returns nil or a WebAuthn::Credential.
  def self.build_challenge_for_user(user)
    return nil if user.webauthn_credentials.blank?

    WebAuthn::Credential.options_for_get(
      allow: user.webauthn_credentials.pluck(:external_id),
      user_verification: "discouraged"
    )
  end
end
