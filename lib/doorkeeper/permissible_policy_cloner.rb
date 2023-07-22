class Doorkeeper::PermissiblePolicyCloner
  def self.clone(request, response)
    case request
    when Doorkeeper::OAuth::RefreshTokenRequest
      original = request.refresh_token
    when Doorkeeper::OAuth::AuthorizationCodeRequest
      original = request.grant
    when Doorkeeper::OAuth::ClientCredentialsRequest
      # No permissible policy exists for this case; just skip.
      return
    when Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceCodeRequest
      original = request.grant
    else
      # Throw an exception so that we don't leak a response without an appropriate permissible policy.
      raise "Unknown authorization strategy: #{request}"
    end

    return unless original.respond_to? :permissible_policy

    response.token.permissible_policy = original.permissible_policy
    response.token.save
  end
end
