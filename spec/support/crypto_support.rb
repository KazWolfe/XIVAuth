module CryptoSupport
  def self.shared_rsa_key
    @shared_rsa_key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def self.shared_ed25519_key
    @shared_ed25519_key ||= Ed25519::SigningKey.generate
  end

  def self.shared_ecdsa_key(curve = "prime256v1")
    @shared_ecdsa_keys ||= {}
    @shared_ecdsa_keys[curve] ||= OpenSSL::PKey::EC.generate(curve)
  end
end
