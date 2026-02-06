module CryptoSupport
  def self.shared_rsa_key
    @shared_rsa_key ||= OpenSSL::PKey::RSA.new(2048)
  end
end
