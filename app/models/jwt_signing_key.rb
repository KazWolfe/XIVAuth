class JwtSigningKey < ApplicationRecord
  encrypts :private_key

  validates :name, presence: true
  validates :private_key, presence: true

  default_scope { order(created_at: :desc) }

  scope :active, -> { where(enabled: true) }

  attr_readonly :public_key, :raw_public_key, :raw_private_key, :jwk

  def raw_public_key
    self[:public_key]
  end

  def raw_private_key
    self[:private_key]
  end

  def jwk
    JWT::JWK.new(private_key, use: 'sig', kid: name)
  end

  def self.jwks
    jwk_set = []
    active.each do |key|
      jwk_set << key.jwk
    end

    JWT::JWK::Set.new(jwk_set)
  end

  def self.preferred_key_for_algorithm(algorithm_name)
    alg_type = JWT::Algos.find(algorithm_name)[1]
    case alg_type.to_s
    when 'JWT::Algos::Rsa', 'JWT::Algos::Ps'
      JwtSigningKeys::RSA.active.first
    when 'JWT::Algos::Eddsa'
      JwtSigningKeys::Ed25519.active.first
    when 'JWT::Algos::Hmac', 'JWT::Algos::HmacRbNaCl'
      JwtSigningKeys::HMAC.active.first
    when 'JWT::Algos::Ecdsa'
      JwtSigningKeys::ECDSA.preferred_key_for_algorithm(algorithm_name)
    else
      nil
    end
  end
end
