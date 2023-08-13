class JwtSigningKeys::HMAC < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?
  validates :size, numericality: { greater_than_or_equal_to: 16 }

  def generate_keypair(size = nil)
    size ||= key_params[:size] || 64
    self[:private_key] = SecureRandom.urlsafe_base64(size)
  end

  def size
    key_params[:size] || Base64.urlsafe_decode64(self[:private_key]).length
  end

  def size=(size)
    return if self[:private_key].present?

    key_params[:size] = size
  end

  def supported_algorithms
    JWT::Algos::Hmac::SUPPORTED
  end
end