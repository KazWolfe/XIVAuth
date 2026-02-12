class PKI::IssuedCertificate < ApplicationRecord
  self.table_name = "pki_issued_certificates"

  # NOTE: Do NOT add dependent: destroy to inbound records for this table! We need to retain an audit log
  # of issued certificates for OCSP and operational purposes.

  belongs_to :certificate_authority, class_name: "PKI::CertificateAuthority"
  belongs_to :subject, polymorphic: true

  belongs_to :requesting_application, class_name: "ClientApplication",
             foreign_key: :requesting_application_id, optional: true

  # Revocation reasons that users are allowed to select to cancel their own certs.
  # All other revocations are system-reserved.
  USER_REVOCATION_REASONS = %w[
    unspecified
    key_compromise
    superseded
    cessation_of_operation
  ].freeze

  enum :revocation_reason, {
    unspecified: "unspecified",
    key_compromise: "key_compromise",
    ca_compromise: "ca_compromise",
    affiliation_changed: "affiliation_changed",
    superseded: "superseded",
    cessation_of_operation: "cessation_of_operation",
    certificate_hold: "certificate_hold",
    privilege_withdrawn: "privilege_withdrawn",
    aa_compromise: "aa_compromise"
  }, prefix: :revocation

  validates :certificate_pem, presence: true
  validates :issued_at, :expires_at, presence: true
  validates :public_key_info, presence: true
  validates :certificate_fingerprint, :public_key_fingerprint, presence: true
  validates :certificate_fingerprint, uniqueness: true  # generally validated by service, but catch here.

  def key_type
    public_key_info["type"]
  end

  def key_bits
    public_key_info["bits"]
  end

  def key_curve
    public_key_info["curve"]
  end

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where(revoked_at: nil).where("expires_at <= ?", Time.current) }

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    !revoked? && expires_at <= Time.current
  end

  def revoke!(reason: "unspecified")
    return if revoked? # we can't re-revoke a certificate

    update!(revoked_at: Time.current, revocation_reason: reason)
  end

  def as_gem_certificate
    @gem_cert ||= CertificateAuthority::Certificate.from_x509_cert(certificate_pem)
  end

  # Converts a serial number back to a UUID for query purposes.
  def self.find_by_serial(serial_integer)
    hex = serial_integer.to_s(16).rjust(32, "0")
    uuid = [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join("-")
    find_by(id: uuid)
  end
end
