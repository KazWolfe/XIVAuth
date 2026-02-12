class PKI::CertificateAuthority < ApplicationRecord
  self.table_name = "pki_certificate_authorities"

  encrypts :private_key

  has_many :issued_certificates, foreign_key: :certificate_authority_id,
           class_name: "PKI::IssuedCertificate"

  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase alphanumeric and hyphens only" }
  validates :certificate_fingerprint, uniqueness: true

  # Block changing slug - this is encoded in cert AIA data, so we can't break it.
  validate :slug_immutable_after_issuance, on: :update

  validates :certificate_pem, presence: true
  validates :private_key, presence: true
  validate :validate_certificate_is_ca, if: :certificate_pem_changed?

  before_save :derive_subject_key_fingerprint, if: :will_save_change_to_certificate_pem?

  enum :revocation_reason, {
    unspecified:            "unspecified",
    key_compromise:         "key_compromise",
    ca_compromise:          "ca_compromise",
    affiliation_changed:    "affiliation_changed",
    superseded:             "superseded",
    cessation_of_operation: "cessation_of_operation",
    certificate_hold:       "certificate_hold",
    privilege_withdrawn:    "privilege_withdrawn",
    aa_compromise:          "aa_compromise"
  }, prefix: :revocation

  scope :active,      -> { where(active: true, revoked_at: nil) }
  scope :inactive,    -> { where(active: false) }
  scope :not_revoked, -> { where(revoked_at: nil) }

  scope :for_subject_type, ->(type) {
    where("? = ANY(allowed_subject_types)", type)
  }

  # Return the newest certificate for a specific subject type.
  # @param subject [User, CharacterRegistration]
  def self.current_for(subject:)
    subject_type = subject.class.name.underscore
    active.for_subject_type(subject_type).order(created_at: :desc).first!
  rescue ActiveRecord::RecordNotFound
    raise "No active PKI certificate authority configured for subject type: #{subject_type}"
  end

  def revoked? = revoked_at.present?

  # Revoke this CA. Sets revoked_at and deactivates.
  # NOTE: This does *not* revoke child certs - that decision is left to the developer performing this operation,
  # as we cannot decide what certs are eligible for revocation.
  def revoke!(reason: "unspecified")
    return if revoked?
    update!(revoked_at: Time.current, revocation_reason: reason, active: false)
  end

  # Convert to a CertificateAuthority::Certificate for use in signing.
  def as_gem_ca_issuer
    ca = CertificateAuthority::Certificate.from_x509_cert(certificate_pem)
    key_mat = CertificateAuthority::MemoryKeyMaterial.new
    key_mat.private_key = OpenSSL::PKey.read(private_key)
    ca.key_material = key_mat

    ca
  end

  def as_openssl_certificate
    OpenSSL::X509::Certificate.new(certificate_pem)
  end

  def as_openssl_pkey
    OpenSSL::PKey.read(private_key)
  end

  private def derive_subject_key_fingerprint
    cert = OpenSSL::X509::Certificate.new(certificate_pem)
    self.certificate_fingerprint = "sha256:#{OpenSSL::Digest::SHA256.hexdigest(cert.to_der)}"
    self.public_key_fingerprint  = "sha256:#{OpenSSL::Digest::SHA256.hexdigest(cert.public_key.to_der)}"
  end

  # Check against RFC 5280 §4.2.1.9 (basicConstraints: CA) and §4.2.1.3 (keyUsage: keyCertSign)
  private def validate_certificate_is_ca
    return if certificate_pem.blank?

    cert = begin
             OpenSSL::X509::Certificate.new(certificate_pem)
           rescue OpenSSL::X509::CertificateError => e
             errors.add(:certificate_pem, "is not a valid X.509 certificate: #{e.message}")
             return
           end

    bc = cert.extensions.find { |e| e.oid == "basicConstraints" }
    if bc.nil? || !bc.value.include?("CA:TRUE")
      errors.add(:certificate_pem, "must have basicConstraints CA:TRUE")
    end

    ku = cert.extensions.find { |e| e.oid == "keyUsage" }
    if ku.nil? || !ku.value.include?("Certificate Sign")
      errors.add(:certificate_pem, "must have keyUsage keyCertSign")
    end
  end

  private def slug_immutable_after_issuance
    return unless will_save_change_to_slug? && issued_certificates.exists?
    errors.add(:slug, "cannot be changed after certificates have been issued")
  end
end
