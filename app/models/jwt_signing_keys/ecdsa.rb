class JwtSigningKeys::ECDSA < JwtSigningKey
  after_initialize :generate_keypair, if: :new_record?
  validates :public_key, presence: true
  validates :curve, inclusion: JWT::JWA::Ecdsa::NAMED_CURVES.keys

  # @return [OpenSSL::PKey::ECDSA] A private RSA key.
  def private_key
    OpenSSL::PKey::EC.new self[:private_key]
  end

  # @param [OpenSSL::PKey::EC] key The RSA private key to store.
  def private_key=(key)
    self[:private_key] = key.export(nil)
    self[:public_key] = key.public_to_pem

    key_params[:curve] = key.public_key&.group&.curve_name
  end

  # @return [OpenSSL::PKey::EC] A public RSA key.
  def public_key
    OpenSSL::PKey::EC.new self[:public_key]
  end

  def generate_keypair(curve = nil)
    curve ||= key_params[:curve] || "prime256v1"
    self.private_key = OpenSSL::PKey::EC.generate(curve)
  end

  def curve
    key_params[:curve] || public_key.group&.curve_name
  end

  def curve=(curve)
    return if self[:private_key].present?

    key_params[:curve] = curve
  end

  def supported_algorithms
    [JWT::JWA::Ecdsa::NAMED_CURVES[curve][:algorithm]]
  end

  def self.preferred_key_for_algorithm(algorithm_name)
    curves = JWT::JWA::Ecdsa::NAMED_CURVES.filter { |_, c| c[:algorithm] == algorithm_name }

    active.where("key_params->'curve' ?| array[:curves]", curves.keys).first
  end
end
