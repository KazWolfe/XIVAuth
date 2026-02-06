class JwtSigningKeys::Ed25519 < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?
  validates :public_key, presence: true

  # @return [Ed25519::SigningKey]
  def private_key
    @private_key ||= ::Ed25519::SigningKey.new(openssl_key.raw_private_key)
  end

  # @param [Ed25519::SigningKey] key
  def private_key=(key)
    if key.is_a?(::Ed25519::SigningKey)
      encoded_key = OpenSSL::PKey.new_raw_private_key("Ed25519", key.to_bytes)

      self[:private_key] = encoded_key.private_to_pem
      self[:public_key] = encoded_key.public_to_pem
    elsif key.is_a?(OpenSSL::PKey::PKey)
      self[:private_key] = key.private_to_pem
      self[:public_key] = key.public_to_pem
    end

    # Clear caches to force fresh reads from the newly set values
    @private_key = nil
    @public_key = nil
  end

  # @return [Ed25519::VerifyKey]
  def public_key
    @public_key ||= ::Ed25519::VerifyKey.new(openssl_key.raw_public_key)
  end

  def generate_keypair
    self.private_key = ::Ed25519::SigningKey.generate
  end

  def supported_algorithms
    %w[EdDSA Ed25519]
  end

  private def openssl_key
    OpenSSL::PKey.read(self[:private_key])
  end
end
