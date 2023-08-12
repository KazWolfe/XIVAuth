class JwtSigningKeys::HMAC < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?

  def generate_keypair(size = 64)
    self[:private_key] = SecureRandom.urlsafe_base64(size)
  end

  def supported_algorithms
    JWT::Algos::Hmac::SUPPORTED
  end
end