class Api::V1::JwtController < Api::V1::ApiController
  skip_before_action :doorkeeper_authorize!, only: %i[jwks]

  def dummy_jwt
    algorithm = request.query_parameters["algorithm"] || JwtSigningKey::DEFAULT_ALGORITHM
    expiry_time = (request.query_parameters[:ttl].to_i or 300)
    issuer = "#{ENV.fetch('APP_URL', 'https://xivauth.net/')}/sandbox"

    payload = {
      jti: SecureRandom.urlsafe_base64(24, padding: false),
      data: "dummy jwt for testing",
      iss: issuer,
      aud: issuer
    }

    payload[:nonce] = params[:nonce] if params[:nonce].present?
    payload[:exp] = Time.now.to_i + expiry_time unless expiry_time.zero?
    payload[:iat] = Time.now.to_i if request.query_parameters[:ignore_iat].blank?

    signing_key = JwtSigningKey.preferred_key_for_algorithm(algorithm.upcase)
    raise ActiveRecord::RecordNotFound if signing_key.blank?

    token = JWT.encode payload, signing_key.private_key, algorithm, kid: signing_key.name, jku: api_v1_jwt_jwks_url

    render json: { token: token }
  end

  def verify
    body = params[:token]

    decoded_jwt = JWT.decode(body, nil, false)
    key_name = decoded_jwt[1]["kid"]
    if key_name.blank?
      render json: { status: "error", error: "No kid specified - cannot verify" }, status: :unprocessable_entity
      return
    end

    signing_key = JwtSigningKey.find_by(name: key_name)
    logger.warn("Validating with signing key #{key_name}", signing_key)

    validation_params = {
      verify_iat: params[:ignore_iat].blank?,
      verify_nbf: params[:ignore_nbf].blank?,
      verify_iss: params[:ignore_iss].blank?,
      iss: ENV.fetch("APP_URL", "https://xivauth.net")
    }

    if decoded_jwt[0]["aud"].present? && params[:ignore_aud].blank?
      validation_params[:verify_aud] = true

      issuer_id = doorkeeper_token&.application&.application_id || "_anonymous"
      validation_params[:aud] = "https://xivauth.net/applications/#{issuer_id}"
    end

    # Validate on-behalf-of authorized party for keys issued via other clients.
    # Used when client A (azp) requests a JWT intended for client B (aud).
    # Validation only takes place from Client B.
    if decoded_jwt[0]["azp"].present?
      extracted_id = decoded_jwt[0]["azp"].split("/").last

      unless doorkeeper_token.application.application.obo_authorizations.exists?(extracted_id)
        raise JWT::InvalidAudError, "Authorized party is not permitted to request a token for this audience."
      end

      validation_params[:azp] = "https://xivauth.net/applications/#{extracted_id}"
    end

    validated_jwt = JWT.decode(body, signing_key.jwk.verify_key, true,
                               algorithms: signing_key.supported_algorithms,
                               **validation_params)

    render json: { status: "valid", jwt_head: validated_jwt[1], jwt_body: validated_jwt[0] }

  rescue JWT::ExpiredSignature => e
    render json: { status: "expired", error: e, jwt_head: decoded_jwt[1], jwt_body: decoded_jwt[0] },
           status: :unprocessable_entity
  rescue JWT::InvalidAudError => e
    render json: { status: "invalid_client", error: e, jwt_head: decoded_jwt[1], jwt_body: decoded_jwt[0] },
           status: :unprocessable_entity
  rescue JWT::DecodeError => e
    render json: { status: "invalid", error: e, jwt_head: decoded_jwt[1], jwt_body: decoded_jwt[0] },
           status: :unprocessable_entity
  end

  def jwks
    render json: JwtSigningKey.jwks.export
  end
end
