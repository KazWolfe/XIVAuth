# frozen_string_literal: true

class Api::V1::JwtController < Api::V1::ApiController
  def dummy_jwt
    algorithm = request.query_parameters['algorithm'] || JwtSigningKey::DEFAULT_ALGORITHM
    payload = { data: 'dummy jwt for testing', id: SecureRandom.uuid }

    expiry_time = (request.query_parameters[:ttl].to_i or 300)
    payload[:exp] = Time.now.to_i + expiry_time unless expiry_time.zero?
    payload[:iat] = Time.now.to_i unless request.query_parameters[:ignore_iat].present?

    signing_key = JwtSigningKey.preferred_key_for_algorithm(algorithm.upcase)
    raise ActiveRecord::RecordNotFound unless signing_key.present?

    token = JWT.encode payload, signing_key.private_key, algorithm, kid: signing_key.name

    render json: { token: token }
  end

  def verify
    body = params[:token]

    decoded_jwt = JWT.decode(body, nil, false)
    key_name = decoded_jwt[1]['kid']
    unless key_name.present?
      render json: { status: 'error', error: 'No kid specified - cannot verify' }, status: :unprocessable_entity
      return
    end

    signing_key = JwtSigningKey.find_by_name(key_name)

    logger.warn("Validating with signing key #{key_name}", signing_key)

    begin
      validated_jwt = JWT.decode(body, signing_key.jwk.verify_key, true,
                                 algorithms: signing_key.supported_algorithms,
                                 verify_iat: true)

      render json: { status: 'valid', jwt_head: validated_jwt[1], jwt_body: validated_jwt[0] }
    rescue JWT::DecodeError => e
      render json: { status: 'invalid', error: e, jwt_head: decoded_jwt[1], jwt_body: decoded_jwt[0] },
             status: :unprocessable_entity
    end
  end

  def jwks
    render json: JwtSigningKey.jwks.export
  end
end
