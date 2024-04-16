class JwtSigningKeys::Ed25519 < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?
  validates :public_key, presence: true

  # @return [RbNaCl::Signatures::Ed25519::SigningKey]
  def private_key
    RbNaCl::Signatures::Ed25519::SigningKey.new(raw_private_key)
  end

  # @param [RbNaCl::Signatures::Ed25519::SigningKey] signing_key
  def private_key=(signing_key)
    self[:private_key] = Base64.urlsafe_encode64(signing_key.to_bytes)
    self[:public_key] = Base64.urlsafe_encode64(signing_key.verify_key.to_bytes)
  end

  # @return [RbNaCl::Signatures::Ed2519::VerifyKey]
  def public_key
    RbNaCl::Signatures::Ed25519::VerifyKey.new raw_public_key
  end

  def raw_private_key
    Base64.urlsafe_decode64(self[:private_key])
  end

  def raw_public_key
    Base64.urlsafe_decode64(self[:public_key])
  end

  def generate_keypair
    self.private_key = RbNaCl::Signatures::Ed25519::SigningKey.generate
  end

  def supported_algorithms
    JWT::JWA::Eddsa::SUPPORTED
  end
end