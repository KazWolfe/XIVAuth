class JwtSigningKeys::Ed25519 < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?
  validates :public_key, presence: true

  def openssl_key
    @openssl_key ||= OpenSSL::PKey.read(self[:private_key])
  end

  # @return [RbNaCl::Signatures::Ed25519::SigningKey]
  def private_key
    @rbnacl_signing_key ||= RbNaCl::Signatures::Ed25519::SigningKey.new openssl_key.raw_private_key
  end

  # @param [OpenSSL::PKey::PKey] pk
  def private_key=(pk)
    self[:private_key] = pk.private_to_pem
    self[:public_key] = pk.public_to_pem
  end

  # @return [RbNaCl::Signatures::Ed2519::VerifyKey]
  def public_key
    @rbnacl_public_key ||= RbNaCl::Signatures::Ed25519::VerifyKey.new openssl_key.raw_public_key
  end

  def generate_keypair
    self.private_key = OpenSSL::PKey.generate_key("ED25519")
  end

  def supported_algorithms
    %w[EdDSA Ed25519]
  end
end
