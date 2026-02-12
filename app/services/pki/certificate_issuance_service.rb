class PKI::CertificateIssuanceService
  class IssuanceError < StandardError; end

  # @param subject [User, CharacterRegistration]
  def initialize(subject:)
    @subject = subject
  end

  # Issues a certificate from a CSR PEM string.
  #
  # @param csr_pem [String] PEM-encoded PKCS#10 CSR
  # @param requesting_application [ClientApplication, nil]
  # @param certificate_authority [PKI::CertificateAuthority, nil] defaults to .current_for
  # @return [PKI::IssuedCertificate] on success (persisted)
  # @return [PKI::IssuancePolicy::Base] with errors when policy.valid? == false
  # @raise [IssuanceError] on signing or persistence failure
  def issue!(csr_pem:, requesting_application: nil, certificate_authority: nil)
    csr = parse_csr!(csr_pem)
    public_key = csr.public_key

    ca_record = certificate_authority || PKI::CertificateAuthority.current_for(subject: @subject)

    # Build and validate policy. On failure, return the policy so the caller
    # can render policy.errors as 422. No signing or persistence occurs.
    policy = PKI::IssuancePolicy.for(
      subject: @subject,
      public_key: public_key,
      certificate_authority: ca_record,
      requesting_application: requesting_application
    )
    return policy unless policy.valid?

    # Ask the policy to build the configured (unsigned) leaf certificate.
    # Policy owns all content decisions: CN, SANs, AIA, CDP, validity, and serial.
    leaf = policy.build_leaf

    # Sign outside of the builder, as the service needs responsibility.
    begin
      leaf.sign!(policy.signing_profile)
    rescue => e
      raise IssuanceError, "Certificate signing failed: #{e.message}"
    end

    cert_pem                = leaf.to_pem
    cert_der                = OpenSSL::X509::Certificate.new(cert_pem).to_der
    certificate_fingerprint = "sha256:#{OpenSSL::Digest::SHA256.hexdigest(cert_der)}"

    begin
      PKI::IssuedCertificate.create!(
        id:                      policy.cert_uuid,
        certificate_authority:   ca_record,
        subject:                 @subject,
        certificate_pem:         cert_pem,
        public_key_info:         build_key_info(public_key),
        issuance_context:        policy.issuance_context,
        certificate_fingerprint: certificate_fingerprint,
        public_key_fingerprint:  policy.public_key_fingerprint,
        issued_at:               leaf.not_before,
        expires_at:              leaf.not_after,
        requesting_application:  requesting_application
      )
    rescue ActiveRecord::RecordInvalid => e
      raise IssuanceError, "Certificate persistence failed: #{e.message}"
    end
  end

  private

  def parse_csr!(csr_pem)
    csr = OpenSSL::X509::Request.new(csr_pem)
    raise IssuanceError, "CSR self-signature verification failed" unless csr.verify(csr.public_key)
    csr
  rescue OpenSSL::X509::RequestError => e
    raise IssuanceError, "Invalid CSR: #{e.message}"
  end

  def build_key_info(public_key)
    case public_key
    when OpenSSL::PKey::RSA
      { "type" => "RSA", "bits" => public_key.n.num_bits }
    when OpenSSL::PKey::EC
      { "type" => "EC", "curve" => public_key.group.curve_name, "bits" => public_key.group.degree }
    else
      { "type" => public_key.class.name }
    end
  end
end
