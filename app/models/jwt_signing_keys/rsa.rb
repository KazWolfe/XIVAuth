class JwtSigningKeys::RSA < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?
  validates :public_key, presence: true
  validates :size, numericality: { greater_than_or_equal_to: 2048 }

  # @return [OpenSSL::PKey::RSA] A private RSA key.
  def private_key
    OpenSSL::PKey::RSA.new self[:private_key]
  end

  # @param [OpenSSL::PKey::RSA] key The RSA private key to store.
  def private_key=(key)
    self[:private_key] = key.export(nil)
    self[:public_key] = key.public_to_pem

    key_params[:size] = key.public_key.n.num_bits
  end

  # @return [OpenSSL::PKey::RSA] A public RSA key.
  def public_key
    OpenSSL::PKey::RSA.new self[:public_key]
  end

  def generate_keypair(size = nil)
    size ||= key_params[:size] || 4096
    self.private_key = OpenSSL::PKey::RSA.generate(size)
  end

  def size=(size)
    return if self[:private_key].present?

    key_params[:size] = size
  end

  def size
    key_params[:size] || public_key.n.num_bits
  end

  def supported_algorithms
    # TODO: Figure out some way to read this from JWT again.
    %w[RS256 RS384 RS512 PS256 PS384 PS512]
  end
end
