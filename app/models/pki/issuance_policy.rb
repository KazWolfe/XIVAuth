class PKI::IssuancePolicy
  # Factory: returns the correct policy object for the given subject.
  # Adding a new subject type = add a subclass + a when branch here.
  def self.for(subject:, public_key:, certificate_authority:, requesting_application: nil)
    policy_class = case subject
                   when User                  then UserPolicy
                   when CharacterRegistration then CharacterRegistrationPolicy
                   else raise ArgumentError, "No PKI issuance policy for #{subject.class}"
                   end
    policy_class.new(
      subject: subject,
      public_key: public_key,
      certificate_authority: certificate_authority,
      requesting_application: requesting_application
    )
  end

  class Base
    include ActiveModel::Validations

    attr_reader :subject, :public_key, :certificate_authority, :cert_uuid, :requesting_application

    def initialize(subject:, public_key:, certificate_authority:, requesting_application: nil)
      @subject = subject
      @public_key = public_key
      @certificate_authority = certificate_authority
      @requesting_application = requesting_application
      @cert_uuid  = SecureRandom.uuid_v7
    end

    validate :validate_key_type
    validate :validate_key_strength
    validate :validate_key_not_revoked
    validate :validate_cert_limit
    validate :validate_renewal_window
    validate :validate_certificate_authority
    validate :validate_key_subject_uniqueness

    def min_rsa_bits      = 2048
    def min_ec_bits       = 256
    def allowed_ec_curves = %w[prime256v1 secp384r1 secp521r1]

    def max_active_certs_per_app = 2


    # @return [String] The Common Name (CN) to include in the final certificate.
    def common_name = raise NotImplementedError

    # @return [ActiveSupport::Duration] How long the certificate should be valid for.
    def validity_period = 1.year

    # @return [Array<String>] SAN URI values, as plain strings.
    def subject_alt_names = []

    # @return [Hash] Extra context to persist to the issuance_context column in the DB.
    def issuance_context = {}


    # @return [Array<String>] keyUsage values for the issued certificate
    def key_usage = raise NotImplementedError

    # @return [Array<String>] extendedKeyUsage OID short names
    def extended_key_usage = raise NotImplementedError

    # Return the signing profile for `.sign!` to use for cert generation.
    def signing_profile
      slug = certificate_authority.slug
      routes = Rails.application.routes.url_helpers

      profile = {
        "extensions" => {
          "basicConstraints"       => { "ca" => false, "critical" => true },
          "keyUsage"               => { "usage" => key_usage, "critical" => true },
          "extendedKeyUsage"       => { "usage" => extended_key_usage },
          "authorityInfoAccess"    => {
            "ocsp"       => [routes.ocsp_certificates_url],
            "ca_issuers" => [routes.ca_cert_url(slug, format: :der)]
          },
          "crlDistributionPoints" => {
            "uris" => [routes.crl_url(slug)]
          },
          # The certificate_authority gem will set AKI and SKI fields.
        }
      }

      sans = subject_alt_names
      profile["extensions"]["subjectAltName"] = { "uris" => sans } if sans.any?

      profile
    end

    # Construct a leaf certificate (without signature) containing core certificate info.
    # @return [CertificateAuthority::Certificate]
    def build_leaf
      now = Time.current

      signing_key_mat = CertificateAuthority::SigningRequestKeyMaterial.new
      signing_key_mat.public_key = public_key

      dn = CertificateAuthority::DistinguishedName.new
      dn.cn = common_name

      leaf = CertificateAuthority::Certificate.new
      leaf.distinguished_name   = dn
      leaf.serial_number.number = @cert_uuid.delete("-").to_i(16)
      leaf.key_material         = signing_key_mat
      leaf.not_before = now - 30.seconds
      leaf.not_after  = now + validity_period
      leaf.parent     = certificate_authority.as_ca_gem_issuer
      leaf
    end

    def public_key_fingerprint
      @public_key_fingerprint ||= "sha256:#{OpenSSL::Digest::SHA256.hexdigest(public_key.to_der)}"
    end

    private

    def validate_key_type
      unless public_key.is_a?(OpenSSL::PKey::RSA) || public_key.is_a?(OpenSSL::PKey::EC)
        errors.add(:public_key, "unsupported key type: #{public_key.class}")
      end
    end

    def validate_key_strength
      case public_key
      when OpenSSL::PKey::RSA
        if public_key.n.num_bits < min_rsa_bits
          errors.add(:public_key, "RSA key too small: #{public_key.n.num_bits} bits (minimum #{min_rsa_bits})")
        end
      when OpenSSL::PKey::EC
        curve = public_key.group.curve_name
        unless allowed_ec_curves.include?(curve)
          errors.add(:public_key, "EC curve not allowed: #{curve} (allowed: #{allowed_ec_curves.join(', ')})")
        end
        if public_key.group.degree < min_ec_bits
          errors.add(:public_key, "EC key too small: #{public_key.group.degree} bits (minimum #{min_ec_bits})")
        end
      end
    end

    def validate_cert_limit
      count = cert_limit_scope
                .where(requesting_application_id: requesting_application&.id)
                .active
                .count
      if count >= max_active_certs_per_app
        errors.add(:base, "certificate limit reached: #{count}/#{max_active_certs_per_app} " \
                          "active certificates for this subject and application")
      end
    end

    # Certificates can only be renewed if at least one year has passed, or 75% of the certificate's lifespan
    # has passed, whichever if first.
    def validate_renewal_window
      prior_certs = PKI::IssuedCertificate
                      .where(subject: subject, public_key_fingerprint: public_key_fingerprint)
                      .active

      return if prior_certs.none?

      renewable = prior_certs.any? do |cert|
        window = [(cert.expires_at - cert.issued_at) * 0.75, 1.year].min
        Time.current >= cert.issued_at + window
      end

      unless renewable
        earliest = prior_certs.map do |cert|
          window = [(cert.expires_at - cert.issued_at) * 0.75, 1.year].min
          cert.issued_at + window
        end.min
        errors.add(:base, "certificate is not yet eligible for renewal; " \
                          "renewal window opens #{earliest.to_fs(:long)}")
      end
    end

    def validate_certificate_authority
      unless certificate_authority.active? && !certificate_authority.revoked?
        errors.add(:certificate_authority, "is not active or has been revoked")
      end
      subject_type = subject.class.name.underscore
      unless certificate_authority.allowed_subject_types.include?(subject_type)
        errors.add(:certificate_authority, "is not permitted to issue for #{subject_type}")
      end
    end

    # Overridable scope to determine limits (per application) for cert issuance purposes.
    def cert_limit_scope
      PKI::IssuedCertificate.where(subject: subject)
    end

    def validate_key_not_revoked
      if PKI::IssuedCertificate.where(public_key_fingerprint: public_key_fingerprint).revoked.exists?
        errors.add(:public_key, "has been revoked and may not be used to issue new certificates")
      end
    end

    def validate_key_subject_uniqueness
      conflict = PKI::IssuedCertificate
                   .where(public_key_fingerprint: public_key_fingerprint)
                   .where.not(subject_type: subject.class.name, subject_id: subject.id)
                   .exists?
      if conflict
        errors.add(:public_key, "is already associated with a different subject - " \
                                "generate a new key pair to issue a certificate for this subject")
      end
    end
  end
end
