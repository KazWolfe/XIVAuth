# X.509 Certificate Issuance Feature

> **Gem audit completed.** All `certificate_authority` gem API assumptions have been verified against source.
> Inaccuracies in this document have been corrected in-place. Required and recommended gem changes
> are tracked separately in `GEM_CHANGES.md`.

## Context

XIVAuth needs to issue X.509 certificates to authenticated entities (Users and verified CharacterRegistrations), enabling PKI-based authentication in addition to the existing JWT attestation flow. The `certificate_authority` (~> 1.1) gem is already in the Gemfile. The feature requires: certificate issuance via CSR, an OCSP responder, auto-revocation tied to CharacterRegistration lifecycle events, and a user-facing management UI.

## Design Decisions

- **CA key storage:** Database model `Pki::CertificateAuthority` with an encrypted `private_key` column (mirrors `JwtSigningKey` pattern). Rails credentials are insufficient because OCSP responses must be signed by the *issuing* CA — if the CA rotates, old certificates need OCSP responses from the old CA's key, so we need multiple CAs with long-term retention even after retirement.
- **CA rotation:** An `active` flag controls whether new certificates can be issued. Retired CAs (`active=false`) remain queryable for OCSP purposes indefinitely.
- **CA revocation:** CAs have `revoked_at` and `revocation_reason` columns (same `pki_revocation_reason` enum as issued certs). Revoked CAs cannot issue new certs but remain queryable for OCSP (the OCSP responder checks the CA's revocation status and can report accordingly). **No automatic cascade** to issued certs — a CA key compromise doesn't necessarily invalidate previously-issued certs (they may have been issued before the compromise). Bulk revocation of child certs, if needed, is an engineer-initiated action.
- **`Pki::IssuedCertificate` references its CA:** Each record has `belongs_to :certificate_authority`. The OCSP responder looks up the cert's CA and signs the response with that CA's key, so rotation is handled correctly.
- **Serial number = record UUID:** The `Pki::IssuedCertificate.id` (UUID) serves as the X.509 serial. Pre-generate a UUID in the service before signing (`cert_uuid = SecureRandom.uuid`), derive the serial integer via `cert_uuid.delete('-').to_i(16)`, sign the cert with it, then `create!(id: cert_uuid)`. No separate `serial_number` column — the PK *is* the serial. OCSP lookup converts integer → UUID via `Pki::IssuedCertificate.find_by_serial(integer)`.
- **Issuance policy objects as gatekeepers:** The policy object hierarchy (`Pki::IssuancePolicy` factory → `Base` → `UserPolicy` / `CharacterRegistrationPolicy`) uses `ActiveModel::Validations`. Policies decide two things: whether a certificate *can* be issued (subject eligibility, key strength, cert limits, CA eligibility), and what data the final certificate *will* have (CN, SANs, extensions, validity period). All issuance context — subject, public key, requesting application, and selected CA — is passed in as attributes. The service selects the CA, builds the policy with all context, then checks `policy.valid?` before signing — it contains no policy logic itself. Adding a new subject type = new subclass + `when` in factory.
- **CSR handling:** Use plain `OpenSSL::X509::Request` to validate CSR self-signature and extract the public key only. Ignore all CSR subject fields. Key strength and type validation is handled by the policy's `valid?` check.
- **OCSP:** Use `certificate_authority` gem's `OCSPRequestReader` / `OCSPResponseBuilder` classes. The `verification_mechanism=` lambda handles database lookup. `parent=` is set to the issuing CA resolved from the cert record. If the cert is not found, the responder returns an error (not a fallback to another CA). Single-CA model per OCSP request for now. Lives at `POST /certificates/ocsp` via a dedicated `Certificates::OcspController < ActionController::Base`.
- **Record creation timing:** `Pki::IssuedCertificate` is persisted only *after* the PEM is fully built in memory. `certificate_pem NOT NULL` enforces this at DB level. When the policy is invalid (`policy.valid? == false`), the service returns the policy's `ActiveModel::Errors` to the caller; signing/persistence failures raise `Pki::CertificateIssuanceService::IssuanceError`. API controller returns 422 for both.
- **Requesting application audit log:** A nullable `requesting_application_id` UUID FK (→ `client_applications`) is stored on `Pki::IssuedCertificate`. API controller passes `doorkeeper_token.application.application` (navigating from `OAuthClient` to its parent `ClientApplication`); UI requests leave it null. Future work: web UI CSR upload.
- **Certificate CN/SAN design:** The Subject DN CN is a human-friendly snapshot (`"Name @ World"` for characters, `"user:<uuid>"` for users) — not the authoritative identity. Consumers MUST use the SAN for identity resolution. Character names and worlds can change (transfers, renames) without invalidating the cert; a stale CN is expected and acceptable. This mirrors S/MIME conventions: CN for display, SAN for machine identity.
- **SAN strategy — URI now, `otherName` (OID) later:** Initial implementation uses `uniformResourceIdentifier` SANs (e.g., `urn:xivauth:character:12345678`). These are universally supported by all X.509 tooling and trivially emitted by the gem. The target design is to additionally include an `otherName` SAN typed with XIVAuth's OID arc — `{ type-id <xivauth-oid>, value UTF8String:<id> }` — which is the proper PKI-native approach for owned identifiers (same pattern as Microsoft UPN in smart card certs). `otherName` requires manual `OpenSSL::ASN1` construction as the `certificate_authority` gem does not expose it; forking the gem is acceptable if necessary. When both are present, consumers should prefer `otherName` for identity resolution and treat the URI as the human-readable fallback. **TODO: add `otherName` SANs once OID is registered.**
- **Public key fingerprint as first-class column:** `subject_key_fingerprint` on `Pki::IssuedCertificate` stores the SHA-256 SPKI fingerprint (`"sha256:<hex>"`, computed via `OpenSSL::Digest::SHA256.hexdigest(public_key.to_der)`) as a dedicated indexed column — not embedded in the `subject_key_info` JSONB. This enables direct DB queries ("all certs for this public key"), efficient key-compromise revocation, and key-continuity tracking across renewals (same fingerprint = same key re-attested to same identity, relevant for e2e crypto key pinning).
- **No `dependent:` on `has_many :pki_issued_certificates`** on CharacterRegistration — records survive the CR's destruction as a permanent audit log. The `after_destroy` callback handles revocation; polymorphic associations don't support PG FK constraints anyway.
- **Per-subject certificate limits:** A configurable limit (default: 2 active certs per subject per requesting application) prevents unbounded issuance. The limit is defined per-policy (overridable by subclass) and enforced via `ActiveModel::Validations`. For character subjects, the limit is tracked against the underlying `FFXIV::Character` (not the `CharacterRegistration`), since a character can have multiple registrations across users. Null `requesting_application_id` (UI/system issuances) is treated as its own bucket.
- **OCSP rate limiting:** The OCSP endpoint is public and unauthenticated per RFC 6960. Rails' built-in `rate_limit` is applied to prevent abuse.
- **CRLs (stubbed):** The CRL endpoint exists at `GET /certificates/crls/:slug` but returns an empty CRL for now. Full CRL population will be implemented later with pre-generation and caching.
- **`/certificates` vs `/pki`:** No strong objection to consolidating. OCSP and roots live under `/certificates/...` with `Certificates::OcspController` and `Certificates::RootsController` as separate controllers to isolate binary DER handling from the standard HTML/JSON UI.

---

## Implementation Notes

- **Gem API verification (completed):** `CertificateAuthority::MemoryKeyMaterial` does not support EC key generation (`generate_key` is RSA-only), but **manually assigning** an EC `OpenSSL::PKey` to `key_material.private_key` works for signing. The `to_certificate_authority` approach in the model is therefore correct as written. The class for CRL revoked entries is **`CertificateAuthority::SerialNumber`** (not `RevokedCertificate`, which does not exist) — call `serial.revoke!(time)` before adding to the CRL. See `GEM_CHANGES.md` for full findings and required gem modifications.

---

## Files to Create

| File | Purpose |
|------|---------|
| `db/migrate/YYYYMMDDHHMMSS_create_pki_tables.rb` | Both PKI tables + enums (single migration) |
| `app/models/pki/certificate_authority.rb` | CA model (encrypted private key, active flag) |
| `app/models/pki/issued_certificate.rb` | Issued cert AR model |
| `app/services/pki/certificate_issuance_service.rb` | Core issuance logic |
| `app/models/pki/issuance_policy.rb` | Policy factory + base class |
| `app/models/pki/issuance_policy/user_policy.rb` | DN/SAN/extensions for User subjects |
| `app/models/pki/issuance_policy/character_registration_policy.rb` | DN/SAN/extensions for CharacterRegistration subjects |
| `app/controllers/certificates_controller.rb` | User-facing UI (index, show, revoke) |
| `app/controllers/certificates/ocsp_controller.rb` | OCSP — `ActionController::Base`, unauthenticated |
| `app/controllers/certificates/roots_controller.rb` | Root CA listing + download (public) |
| `app/controllers/certificates/crls_controller.rb` | CRL endpoint — `ActionController::Base`, unauthenticated |
| `app/controllers/api/v1/certificates_controller.rb` | REST API (list, show, request, revoke) |
| `app/views/certificates/index.html.erb` | Certificate list |
| `app/views/certificates/show.html.erb` | Certificate detail |
| `app/views/certificates/roots/index.html.erb` | Trust anchor list |
| `app/views/certificates/roots/show.html.erb` | Root CA download/detail |
| `lib/tasks/pki.rake` | `pki:generate_ca` rake task for dev CA setup |
| `spec/factories/pki_certificate_authorities.rb` | FactoryBot factory for CA |
| `spec/factories/pki_issued_certificates.rb` | FactoryBot factory for issued certs |
| `spec/support/pki_support.rb` | Shared OpenSSL test CA helpers |
| `spec/models/pki/certificate_authority_spec.rb` | CA model specs |
| `spec/models/pki/issued_certificate_spec.rb` | Issued cert model specs |
| `spec/services/pki/certificate_issuance_service_spec.rb` | Service specs |
| `spec/requests/certificates/ocsp_spec.rb` | OCSP controller specs (use `spec/requests/` — Rails 8 convention) |
| `spec/requests/certificates/crls_spec.rb` | CRL controller specs |
| `spec/requests/api/v1/certificates_spec.rb` | API controller specs |

## Files to Modify

| File                                   | Change                                                                                                                                                                                                                                                                                                                            |
|----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `config/routes.rb`                     | Add top-level `/certificates` resource block (UI + OCSP + roots); add `/api/v1/certificates` API routes                                                                                                                                                                                                                           |
| `app/models/character_registration.rb` | Add `has_many :pki_issued_certificates`, two auto-revocation callbacks                                                                                                                                                                                                                                                            |
| `app/models/user.rb`                   | Add `has_many :pki_issued_certificates, as: :subject`, auto-revocation callback on user deletion                                                                                                                                                                                                                                  |
| `app/models/ability.rb`                | Add CanCanCan rules: `can %i[read revoke], Pki::IssuedCertificate, subject_type: "User", subject_id: user.id` for user-owned certs; character-registration certs require a block that checks `user.character_registrations.verified.pluck(:id).include?(record.subject_id)` (no simple hash condition due to polymorphic subject) |

---

## Migrations

**Migration: `create_pki_tables`**
```ruby
# Use def up/def down (not def change) because of create_enum.
def up
  # --- Enums ---

  # PG enum for which subject types a CA is allowed to issue certs for.
  # An empty array means "no subject types" (effectively disabled for issuance).
  # Default is all types — add new types here when new subject types are introduced.
  create_enum :pki_subject_type, %w[user character_registration]

  # Full RFC 5280 CRLReason enumeration (value 7 is unassigned and omitted).
  # Shared by both pki_certificate_authorities and pki_issued_certificates.
  create_enum :pki_revocation_reason, %w[
    unspecified key_compromise ca_compromise affiliation_changed
    superseded cessation_of_operation certificate_hold
    remove_from_crl privilege_withdrawn aa_compromise
  ]

  # --- Tables ---

  create_table :pki_certificate_authorities, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
    # slug: URL-safe human identifier, e.g. "xivauth-root-2026". Used in routes and CRL URLs.
    # PK remains UUID so FKs in pki_issued_certificates are stable even if slug is renamed.
    t.string   :slug,            null: false
    t.text     :certificate_pem, null: false  # CA cert (PEM)
    t.text     :private_key,     null: false  # encrypted at rest via ActiveRecord::Encryption
    t.boolean  :active,          null: false, default: true  # false = retired; still used for OCSP/CRL
    t.enum     :allowed_subject_types, enum_type: :pki_subject_type,
               array: true, null: false, default: ["user", "character_registration"]
    t.datetime :expires_at                    # informational
    t.datetime :revoked_at                   # null = not revoked
    t.enum     :revocation_reason, enum_type: :pki_revocation_reason, null: true
    t.timestamps
  end
  add_index :pki_certificate_authorities, :slug, unique: true
  add_index :pki_certificate_authorities, :active

  create_table :pki_issued_certificates, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
    t.references :certificate_authority, type: :uuid, null: false,
                 foreign_key: { to_table: :pki_certificate_authorities }
    # Nullable reference to client_applications (ClientApplication).
    # Set when the cert was requested via API (navigate: doorkeeper_token.application.application).
    # Null for system/UI issuances. No FK constraint — applications may be deleted
    # while certs must survive as audit records.
    t.uuid    :requesting_application_id
    t.string  :subject_type, null: false
    t.uuid    :subject_id,   null: false
    t.text    :certificate_pem, null: false
    # No serial_number column — id IS the serial (see Pki::IssuedCertificate.find_by_serial)
    t.datetime :issued_at,  null: false
    t.datetime :expires_at, null: false
    # Structured subject public key metadata, populated at issuance from OpenSSL:
    # RSA: { "type" => "RSA", "bits" => 4096 }
    # EC:  { "type" => "EC",  "curve" => "prime256v1", "bits" => 256 }
    # No enum needed — JSONB handles new key types without schema changes.
    t.jsonb   :subject_key_info, null: false, default: {}
    # SHA-256 fingerprint of the SubjectPublicKeyInfo DER (SPKI fingerprint), prefixed "sha256:".
    # Stored as a first-class column (not inside subject_key_info) to enable direct indexing.
    # Enables: "find all certs bound to this public key" — critical for key-compromise revocation
    # and for key-continuity tracking across renewals (same key re-attested to the same identity).
    # Computed as: "sha256:#{OpenSSL::Digest::SHA256.hexdigest(public_key.to_der)}"
    t.string  :subject_key_fingerprint, null: false
    t.datetime :revoked_at
    t.enum    :revocation_reason, enum_type: :pki_revocation_reason, null: true
    t.timestamps
  end
  add_index :pki_issued_certificates, [:subject_type, :subject_id]
  add_index :pki_issued_certificates, :certificate_authority_id
  add_index :pki_issued_certificates, :requesting_application_id
  add_index :pki_issued_certificates, :subject_key_fingerprint
end

def down
  drop_table :pki_issued_certificates
  drop_table :pki_certificate_authorities
  drop_enum :pki_revocation_reason
  drop_enum :pki_subject_type
end
```

---

## Model: `Pki::CertificateAuthority`

```ruby
# app/models/pki/certificate_authority.rb
class Pki::CertificateAuthority < ApplicationRecord
  self.table_name = "pki_certificate_authorities"

  encrypts :private_key   # ActiveRecord::Encryption, same pattern as JwtSigningKey

  has_many :pki_issued_certificates, foreign_key: :certificate_authority_id,
           class_name: "Pki::IssuedCertificate"

  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase alphanumeric and hyphens only" }
  # Slug is embedded in every issued cert's CDP and AIA extensions — changing it
  # would silently break revocation checking for all previously issued certs.
  validate :slug_immutable_after_issuance, on: :update

  validates :certificate_pem, presence: true
  validates :private_key, presence: true

  enum :revocation_reason, {
    unspecified:            "unspecified",
    key_compromise:         "key_compromise",
    ca_compromise:          "ca_compromise",
    affiliation_changed:    "affiliation_changed",
    superseded:             "superseded",
    cessation_of_operation: "cessation_of_operation",
    certificate_hold:       "certificate_hold",
    remove_from_crl:        "remove_from_crl",
    privilege_withdrawn:    "privilege_withdrawn",
    aa_compromise:          "aa_compromise"
  }, prefix: :revocation

  scope :active,   -> { where(active: true, revoked_at: nil) }
  scope :inactive, -> { where(active: false) }
  scope :not_revoked, -> { where(revoked_at: nil) }

  # Scope to CAs permitted to issue for a given subject type string ("user", "character_registration").
  scope :for_subject_type, ->(type) {
    where("? = ANY(allowed_subject_types)", type)
  }

  # Returns the most recently created active, non-revoked CA that can issue for the given subject.
  # @param subject [User, CharacterRegistration]
  def self.current_for(subject:)
    subject_type = subject.class.name.underscore  # "user" or "character_registration"
    active.for_subject_type(subject_type).order(created_at: :desc).first!
  rescue ActiveRecord::RecordNotFound
    raise "No active PKI certificate authority configured for subject type: #{subject_type}"
  end

  def revoked? = revoked_at.present?

  # Revoke this CA. Sets revoked_at and deactivates.
  # Does NOT automatically cascade to issued certs — that's an engineer decision.
  # (Certs issued before a key compromise may still be valid.)
  def revoke!(reason: "unspecified")
    return if revoked?
    update!(revoked_at: Time.current, revocation_reason: reason, active: false)
  end

  private def slug_immutable_after_issuance
    return unless will_save_change_to_slug? && pki_issued_certificates.exists?
    errors.add(:slug, "cannot be changed after certificates have been issued")
  end

  # Wraps this CA's cert+key as a CertificateAuthority::Certificate for signing.
  # Uses OpenSSL::PKey.read to handle any key type (RSA, EC, etc.) transparently.
  # The parsed OpenSSL::X509::Certificate is also loaded so that the gem can embed
  # issuer information in OCSP responses and CRLs (needed for client signature verification).
  # NOTE: verify exact gem API for loading an existing cert — it may be `set_openssl_fields`,
  # direct assignment to an internal ivar, or simply unused by the gem (key-only is sufficient).
  # Confirm against gem source during implementation.
  def to_certificate_authority
    ca = CertificateAuthority::Certificate.new
    ca.signing_entity = true
    key_mat = CertificateAuthority::MemoryKeyMaterial.new
    key_mat.private_key = OpenSSL::PKey.read(private_key)
    ca.key_material = key_mat
    # Load parsed cert so issuer fields are available to OCSP/CRL builders:
    ca.openssl_body = OpenSSL::X509::Certificate.new(certificate_pem)
    ca
  end
end
```

## Model: `Pki::IssuedCertificate`

```ruby
# app/models/pki/issued_certificate.rb
class Pki::IssuedCertificate < ApplicationRecord
  self.table_name = "pki_issued_certificates"

  belongs_to :certificate_authority, class_name: "Pki::CertificateAuthority"
  belongs_to :subject, polymorphic: true
  # requesting_application: the ClientApplication (parent) that initiated the request.
  # In API controller: doorkeeper_token.application.application
  # (OAuthClient#application → ClientApplication)
  belongs_to :requesting_application, class_name: "ClientApplication",
             foreign_key: :requesting_application_id, optional: true

  # revocation_reason is a native PG enum (:pki_revocation_reason).
  # Values match RFC 5280 CRLReason (value 7 unassigned, omitted).
  # user_requested is an XIVAuth extension not in RFC 5280 — kept out of the PG enum;
  # see note below.
  enum :revocation_reason, {
    unspecified:            "unspecified",
    key_compromise:         "key_compromise",
    ca_compromise:          "ca_compromise",
    affiliation_changed:    "affiliation_changed",
    superseded:             "superseded",
    cessation_of_operation: "cessation_of_operation",
    certificate_hold:       "certificate_hold",
    remove_from_crl:        "remove_from_crl",
    privilege_withdrawn:    "privilege_withdrawn",
    aa_compromise:          "aa_compromise"
  }, prefix: :revocation
  # Note: the earlier "user_requested" reason was an app-internal convenience label.
  # Since this is now a strict RFC 5280 enum, use "unspecified" for user-initiated
  # revocations, or add a separate nullable :revocation_initiator column later.

  validates :certificate_pem, presence: true
  validates :issued_at, :expires_at, presence: true
  validates :subject_key_info, presence: true

  validates :subject_key_fingerprint, presence: true

  # Convenience accessors for the JSONB key metadata
  def key_type        = subject_key_info["type"]        # "RSA" or "EC"
  def key_bits        = subject_key_info["bits"]        # integer
  def key_curve       = subject_key_info["curve"]       # EC curve name, nil for RSA
  # subject_key_fingerprint is a dedicated column (not in JSONB) to allow direct indexing.
  # Format: "sha256:<hex>" (SHA-256 of SubjectPublicKeyInfo DER).
  # Use it to find all certs bound to a given key: .where(subject_key_fingerprint: fp)

  scope :active,  -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where(revoked_at: nil).where("expires_at <= ?", Time.current) }

  def active?  = revoked_at.nil? && expires_at > Time.current
  def revoked? = revoked_at.present?
  def expired? = !revoked? && expires_at <= Time.current

  def revoke!(reason: "unspecified")
    return if revoked?  # idempotent — preserve original revoked_at timestamp
    update!(revoked_at: Time.current, revocation_reason: reason)
  end

  # Converts an X.509 serial integer (as found in OCSP requests) back to the UUID
  # that serves as this record's primary key.
  # The inverse of: uuid.delete('-').to_i(16)
  def self.find_by_serial(serial_integer)
    hex = serial_integer.to_s(16).rjust(32, '0')
    uuid = [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join('-')
    find_by(id: uuid)
  end
end
```

---

## Policy Object Hierarchy: `Pki::IssuancePolicy`

Three files. Uses `ActiveModel::Validations` (not ActiveRecord). The policy decides two things:
whether a certificate *can* be issued (validations), and what data the final certificate *will*
have (cert content methods). All issuance context is passed in as attributes. The service
orchestrates (CA selection, serial generation, signing) and delegates all policy logic here.

**`app/models/pki/issuance_policy.rb`** — factory + base class:
```ruby
class Pki::IssuancePolicy
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

  # Base class — subclasses override constraint methods and cert content methods.
  class Base
    include ActiveModel::Validations

    attr_reader :subject, :public_key, :certificate_authority, :requesting_application

    def initialize(subject:, public_key:, certificate_authority:, requesting_application: nil)
      @subject = subject
      @public_key = public_key
      @certificate_authority = certificate_authority
      @requesting_application = requesting_application
    end

    # ============================================================
    # Validations — "can this certificate be issued?"
    # Subclasses add their own with `validate :method_name`.
    # ============================================================

    validate :validate_key_type
    validate :validate_key_strength
    validate :validate_cert_limit
    validate :validate_certificate_authority

    # --- Key constraints (subclasses may override to tighten) ---

    def min_rsa_bits = 2048
    def min_ec_bits  = 256  # P-256 and above
    def allowed_ec_curves = %w[prime256v1 secp384r1 secp521r1]

    # --- Issuance limits (subclasses may override) ---

    # Max active certs per subject per requesting application.
    # For character subjects, tracked against FFXIV::Character (see CharacterRegistrationPolicy).
    def max_active_certs_per_app = 2

    # ============================================================
    # Cert content — "what data will the certificate have?"
    # Subclasses must/may override these.
    # ============================================================

    # @return [String] the CN to embed in the cert subject DN
    def common_name = raise NotImplementedError

    # @return [ActiveSupport::Duration] how long issued certs should be valid.
    def validity_period = 1.year

    # @return [Array<String>] SAN values, e.g. ["URI:urn:xivauth:user:uuid"]
    def subject_alt_names = []

    # Returns the full signing profile hash for CertificateAuthority::Certificate#sign!
    # Combines key-type-driven keyUsage with subject-driven SANs.
    def extensions
      key_usage = case public_key
                  when OpenSSL::PKey::EC  then %w[digitalSignature keyAgreement]
                  when OpenSSL::PKey::RSA then %w[digitalSignature keyEncipherment]
                  else %w[digitalSignature]  # fallback; validate_key_type catches unsupported types
                  end

      profile = {
        "extensions" => {
          "basicConstraints" => { "ca" => false },
          "keyUsage"         => { "usage" => key_usage },
          "extendedKeyUsage" => { "usage" => %w[clientAuth] }
          # AIA and crlDistributionPoints are added by the service (depend on CA slug context)
        }
      }

      sans = subject_alt_names
      profile["extensions"]["subjectAltName"] = { "dns_names" => [], "uris" => sans } if sans.any?

      profile
    end

    private

    # --- Validation methods ---

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
        unless curve.in?(allowed_ec_curves)
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

    def validate_certificate_authority
      unless certificate_authority.active? && !certificate_authority.revoked?
        errors.add(:certificate_authority, "is not active or has been revoked")
      end
      subject_type = subject.class.name.underscore
      unless certificate_authority.allowed_subject_types.include?(subject_type)
        errors.add(:certificate_authority, "is not permitted to issue for #{subject_type}")
      end
    end

    # Default: count certs issued to this exact subject.
    # CharacterRegistrationPolicy overrides to count by FFXIV::Character.
    def cert_limit_scope
      Pki::IssuedCertificate.where(subject: subject)
    end
  end
end
```

**`app/models/pki/issuance_policy/user_policy.rb`**:
```ruby
class Pki::IssuancePolicy::UserPolicy < Pki::IssuancePolicy::Base
  def common_name      = "user:#{subject.id}"
  def validity_period  = 1.year
  # TODO: add URI SAN ("urn:xivauth:user:<uuid>") + otherName SAN (OID TBD) once OID is registered.
  def subject_alt_names = []
end
```

**`app/models/pki/issuance_policy/character_registration_policy.rb`**:
```ruby
class Pki::IssuancePolicy::CharacterRegistrationPolicy < Pki::IssuancePolicy::Base
  # CN is a human-friendly snapshot of the character's name and world at issuance time.
  # It is intentionally NOT the authoritative identity — character names and worlds can
  # change (transfers, renames) without invalidating the certificate. The CN becoming
  # "stale" is not an error; the certificate is a public-key ↔ verified-identity binding,
  # not a name record. Consumers MUST use the SAN URI for identity, not the CN.
  def common_name     = "#{subject.character.name} @ #{subject.character.home_world}"
  def validity_period = 1.year

  # SANs encode the stable identity; consumers use these, not the CN.
  # TODO: add SANs once OID is registered.
  def subject_alt_names = []

  # CharacterRegistrations must be verified to issue certs.
  validate :validate_character_verified

  private

  def validate_character_verified
    errors.add(:subject, "CharacterRegistration must be verified") unless subject.verified?
  end

  # Cert limit tracks by FFXIV::Character, not the specific CharacterRegistration,
  # since a character can have multiple registrations across users.
  def cert_limit_scope
    character = subject.character
    cr_ids = CharacterRegistration.where(character: character).select(:id)
    Pki::IssuedCertificate.where(subject_type: "CharacterRegistration", subject_id: cr_ids)
  end
end
```

---

## Service: `Pki::CertificateIssuanceService`

`app/services/pki/certificate_issuance_service.rb`

```ruby
# Usage: Pki::CertificateIssuanceService.new(subject: user_or_char_reg).issue!(
#          csr_pem:,
#          requesting_application: nil,   # ClientApplication or nil
#          certificate_authority: nil     # Pki::CertificateAuthority or nil (defaults to .current_for)
#        )
# Returns: Pki::IssuedCertificate (persisted) on success
#          Pki::IssuancePolicy::Base (invalid, with .errors) on policy failure — caller checks .valid?
# Raises:  Pki::CertificateIssuanceService::IssuanceError on signing/persistence failures
```

Key steps (the service orchestrates; the policy decides):
1. Parse CSR with `OpenSSL::X509::Request.new(csr_pem)`, verify self-signature, extract `.public_key` only
2. Load issuing CA: `ca_record = certificate_authority || Pki::CertificateAuthority.current_for(subject: @subject)`
3. Build policy with all context: `policy = Pki::IssuancePolicy.for(subject:, public_key:, certificate_authority: ca_record, requesting_application:)`
4. **Policy validation:** `return policy unless policy.valid?` — the policy checks everything (subject eligibility, key strength/type, cert limits, CA eligibility). On failure, the caller gets back the invalid policy with standard `ActiveModel::Errors`. The API controller renders `policy.errors` as 422.
5. Pre-generate UUID: `cert_uuid = SecureRandom.uuid`; derive X.509 serial: `serial_int = cert_uuid.delete('-').to_i(16)`
6. Build extensions profile:
   ```ruby
   profile = policy.extensions
   # AIA and CDP depend on CA context (slug), so the service adds them here.
   base_url = Rails.application.routes.url_helpers.root_url.chomp('/')
   profile["extensions"]["authorityInfoAccess"] = {
     "ocsp"       => ["#{base_url}/certificates/ocsp"],
     "ca_issuers" => ["#{base_url}/certificates/roots/#{ca_record.slug}"]
   }
   profile["extensions"]["crlDistributionPoints"] = {
     "uris" => ["#{base_url}/certificates/crls/#{ca_record.slug}"]
   }
   # NOTE: Extension values are plain URI strings — the gem's extension classes add the
   # "URI:", "OCSP;URI:", "caIssuers;URI:" prefixes themselves in their to_s methods.
   # Passing pre-prefixed strings would double the prefix in the signed cert.
   # CDP key is "uris" (plural) — the legacy singular setter "uri=" also works but is
   # an appending setter, not a direct array assignment.
   ```
7. Build leaf `CertificateAuthority::Certificate` — set `subject.common_name = policy.common_name`, `serial_number.number = serial_int`, assign `key_material.public_key`, set `not_before = Time.current` / `not_after = Time.current + policy.validity_period`, set `parent = ca_record.to_certificate_authority`, call `sign!(profile)`
8. Build `subject_key_info` and `subject_key_fingerprint` from the public key:
   - RSA: `subject_key_info = { "type" => "RSA", "bits" => public_key.n.num_bits }`
   - EC:  `subject_key_info = { "type" => "EC", "curve" => public_key.group.curve_name, "bits" => public_key.group.degree }`
   - Fingerprint (both key types): `subject_key_fingerprint = "sha256:#{OpenSSL::Digest::SHA256.hexdigest(public_key.to_der)}"`
   - `public_key.to_der` produces the SubjectPublicKeyInfo (SPKI) DER — same format used in TLS cert pinning and `openssl pkey -pubout`.
9. Only after successful `sign!` — `Pki::IssuedCertificate.create!(id: cert_uuid, certificate_authority: ca_record, subject:, certificate_pem: cert.to_pem, subject_key_info:, subject_key_fingerprint:, issued_at:, expires_at:, requesting_application:)`

---

## OCSP Controller: `Certificates::OcspController`

Inherits `ActionController::Base` (NOT `ApplicationController`) to avoid Devise filters.
Handles binary DER over HTTP — kept separate from `CertificatesController` for this reason.

OCSP requests may cover serials from any CA including retired ones. The responder:
- Resolves the CA for **every** recognized serial and rejects the request if multiple distinct CAs are found.
- Returns `malformedRequest` for all-unknown batches.

**Multi-CA rejection:** A single `BasicOCSPResponse` is signed by one key. For the status of a cert to be trustworthy, the response must be signed by that cert's issuing CA (or an explicitly delegated OCSP responder). If certs from CA A and CA B appear in the same request, no single key can validly authorize all statuses — a CA A-signed response for a CA B cert will be rejected by the client. We therefore reject mixed-CA requests outright with `malformedRequest` and an `X-OCSP-Error` header. Well-behaved clients won't send mixed-CA requests anyway; they build OCSP requests from each cert's own AIA extension URL.

OCSP results will have a cache assigned via HTTP headers (exact details TBD). Server-side caching may be added later.

```ruby
class Certificates::OcspController < ActionController::Base
  rate_limit to: 5, within: 1.minute

  # POST /certificates/ocsp
  def respond
    ocsp_reader = CertificateAuthority::OCSPRequestReader.from_der(request.body.read)

    # Resolve the issuing CA for every recognized serial.
    # OCSPRequestReader#serial_numbers returns OpenSSL::BN objects — .to_i before find_by_serial.
    ca_records = ocsp_reader.serial_numbers
                   .map { |s| Pki::IssuedCertificate.find_by_serial(s.to_i)&.certificate_authority }
                   .compact
                   .uniq

    if ca_records.empty?
      # No recognized serials — cannot determine which CA to sign with.
      # Return OCSP "malformedRequest" per RFC 6960 §2.3.
      return send_data OpenSSL::OCSP::Response.create(
                         OpenSSL::OCSP::RESPONSE_STATUS_MALFORMEDREQUEST, nil
                       ).to_der,
                       type: "application/ocsp-response"
    end

    if ca_records.size > 1
      # Mixed-CA request: a single BasicOCSPResponse can only be signed by one CA key,
      # so we cannot produce a valid response for certs issued by different CAs.
      # Reject with malformedRequest and explain via a custom header.
      response.set_header("X-OCSP-Error", "certificates from multiple CAs was requested")
      return send_data OpenSSL::OCSP::Response.create(
                         OpenSSL::OCSP::RESPONSE_STATUS_MALFORMEDREQUEST, nil
                       ).to_der,
                       type: "application/ocsp-response"
    end

    issuing_ca_record = ca_records.first

    builder = CertificateAuthority::OCSPResponseBuilder.from_request_reader(ocsp_reader)
    builder.parent = issuing_ca_record.to_certificate_authority

    # The gem calls this lambda ONCE PER SERIAL (not batched) with an OpenSSL::BN.
    # Return value must be [integer_status, integer_reason] using the gem's constants.
    # There is no UNKNOWN constant in the gem — use OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN directly.
    builder.verification_mechanism = ->(serial_bn) {
      cert = Pki::IssuedCertificate.find_by_serial(serial_bn.to_i)
      if    cert.nil?     then [OpenSSL::OCSP::V_CERTSTATUS_UNKNOWN, 0]
      elsif cert.revoked? then [CertificateAuthority::OCSPResponseBuilder::REVOKED,
                                CertificateAuthority::OCSPResponseBuilder::UNSPECIFIED]
      else                     [CertificateAuthority::OCSPResponseBuilder::GOOD,
                                CertificateAuthority::OCSPResponseBuilder::NO_REASON]
      end
      # Note: CA revocation is a chain-of-trust concern — clients check the CA cert's
      # status separately. The OCSP responder reports the individual cert's status only.
    }

    send_data builder.build_response.to_der, type: "application/ocsp-response"
  end
end
```

---

## CRL Controller: `Certificates::CrlsController`

Inherits `ActionController::Base`. Unauthenticated — CRLs are public per RFC 5280.

```ruby
# GET /certificates/crls/:ca_certificate_id
# Returns: application/pkix-crl (DER binary)
def show
  ca_record = Pki::CertificateAuthority.find_by!(slug: params[:slug])

  # revoked = ca_record.pki_issued_certificates.revoked
  revoked = []   # TODO: CRLs will come later because we can't fetch this from the DB every time.
  
  crl = CertificateAuthority::CertificateRevocationList.new
  crl.parent     = ca_record.to_certificate_authority
  crl.next_update = 24.hours.from_now  # TBD: make configurable

  revoked.each do |issued_cert|
    # The gem's CRL <<operator accepts CertificateAuthority::SerialNumber objects that have
    # been revoked via revoke!(time). There is no RevokedCertificate class.
    # LIMITATION: the gem does not write reasonCode extensions into CRL entries — reason
    # codes are silently dropped. Full CRL population will need OpenSSL::X509::CRL directly
    # (or a gem modification) to include RFC 5280 reason codes. Acceptable for stubbed impl.
    serial = CertificateAuthority::SerialNumber.new
    serial.number = issued_cert.id.delete('-').to_i(16)
    serial.revoke!(issued_cert.revoked_at)
    crl << serial
  end

  crl.sign!

  send_data crl.to_der, type: "application/pkix-crl", disposition: "inline"
rescue ActiveRecord::RecordNotFound
  head :not_found
end
```

**Note:** `CertificateAuthority::RevokedCertificate` does not exist. The correct class is `CertificateAuthority::SerialNumber` — call `.revoke!(time)` before passing to `crl <<`. The gem does not include `reasonCode` extensions in CRL entries. Full CRL population (when implemented) will require either a gem modification or direct `OpenSSL::X509::CRL` construction for reason code support. See `GEM_CHANGES.md`.

---

## Routes

```ruby
# Top-level /certificates (UI + PKI infrastructure, authenticated where needed)
resources :certificates, only: %i[index show] do
  member { post :revoke }
  collection do
    post :ocsp, controller: "certificates/ocsp", action: :respond
    resources :roots, controller: "certificates/roots", only: %i[index show], param: :slug
    resources :crls,  controller: "certificates/crls",  only: %i[show],        param: :slug
  end
end
# Generates:
#   GET    /certificates                → certificates#index
#   GET    /certificates/:id            → certificates#show
#   POST   /certificates/:id/revoke    → certificates#revoke
#   POST   /certificates/ocsp          → certificates/ocsp#respond    (unauthenticated)
#   GET    /certificates/roots          → certificates/roots#index    (public)
#   GET    /certificates/roots/:slug    → certificates/roots#show     (public)
#   GET    /certificates/crls/:slug     → certificates/crls#show      (public)

# Inside `namespace "api" > namespace "v1"` block
resources :certificates, only: %i[index show] do
  collection { post :request, action: :request_cert }
  member     { post :revoke }
end
# Generates:
#   GET  /api/v1/certificates               → api/v1/certificates#index
#   GET  /api/v1/certificates/:id           → api/v1/certificates#show
#   POST /api/v1/certificates/request       → api/v1/certificates#request_cert
#   POST /api/v1/certificates/:id/revoke    → api/v1/certificates#revoke
```

---

## CharacterRegistration Changes

```ruby
has_many :pki_issued_certificates, class_name: "Pki::IssuedCertificate",
         as: :subject  # no dependent: — records survive as permanent audit log

after_update  :revoke_pki_certificates_if_unverified
after_destroy :revoke_pki_certificates_on_destroy

private def revoke_pki_certificates_if_unverified
  return unless saved_change_to_verified_at? && verified_at.nil?
  pki_issued_certificates.active.find_each { |c| c.revoke!(reason: "affiliation_changed") }
end

private def revoke_pki_certificates_on_destroy
  pki_issued_certificates.active.find_each { |c| c.revoke!(reason: "affiliation_changed") }
end
```

`saved_change_to_verified_at?` (ActiveRecord dirty tracking) ensures revocation only fires when `verified_at` is actually cleared, not on unrelated updates.

---

## CA Setup (Developer Action Required)

CAs are stored in the database with an encrypted private key:

```bash
openssl genrsa -out ca.key 4096
openssl req -new -x509 -key ca.key -days 3650 -subj "/CN=XIVAuth Dev CA" -out ca.crt
```

A `pki:generate_ca` rake task automates this for development (generates key + self-signed cert, loads into DB). Production CA key generation happens offline; key is imported via a secure `pki:import_ca` rake task or console.

The `GET /certificates/roots` page will display trust anchors. The "true" root CA (offline, hardware-generated) can be manually entered as a display-only entry (no private key required for display). Intermediates live in `pki_certificate_authorities`. Architecture detail TBD when chain-of-trust depth is decided.

---

## Test Strategy

**`spec/support/pki_support.rb`** — 2048-bit test CA key/cert using raw OpenSSL (not the gem). Provides `PkiSupport.generate_leaf_pem`. Used in factories; avoids generating real certs in every test.

**Factories** — `:pki_certificate_authority`, `:pki_issued_certificate` (traits: `:for_character_registration`, `:revoked`, `:expired`). The `certificate_pem` uses `PkiSupport.generate_leaf_pem`.

**Key spec areas:**
- `Pki::IssuedCertificate`: `find_by_serial` round-trips (UUID → int → UUID); scope correctness; `revoke!` persistence; `revoke!` is idempotent (second call is no-op, preserves original timestamp)
- `Pki::IssuancePolicy` (ActiveModel validations): `valid?` rejects RSA < 2048 bits, unsupported EC curves, unsupported key types, returns multiple errors at once via `errors`; rejects inactive/revoked CA; rejects CA not permitted for subject type; `CharacterRegistrationPolicy` rejects unverified subject, tracks cert limit by FFXIV::Character not CharacterRegistration; cert limit per subject per app; extensions produce correct `keyEncipherment`/`keyAgreement` per key type
- `CharacterRegistration` callbacks: clearing `verified_at` revokes certs; unrelated updates don't; `destroy` revokes certs
- `Pki::CertificateIssuanceService`: rejects invalid CSR; ignores CSR CN; returns invalid policy (with `errors`) when `policy.valid?` is false; correct extensions for RSA vs EC; sets `requesting_application` when provided; record `id` matches cert serial (round-trip); no record written on failure
- `Pki::CertificateAuthority`: `current_for` returns correct CA for each subject type; raises when no matching active CA; `for_subject_type` scope filters correctly; `revoke!` is idempotent (no cascade — engineer-initiated); revoked CA excluded from `active` scope
- `Certificates::OcspController` (`spec/requests/certificates/ocsp_spec.rb`): correct status for good/revoked/unknown; uses retired CA key for retired-CA certs; `malformedRequest` DER response when no serial is recognized; `malformedRequest` DER response + `X-OCSP-Error` header when request spans multiple CAs; rate limited
- `Certificates::CrlsController` (`spec/requests/certificates/crls_spec.rb`): 404 for unknown CA; DER response includes all revoked certs for that CA and no others; empty CRL for CA with no revocations
- `Api::V1::CertificatesController` (`spec/requests/api/v1/certificates_spec.rb`): list/show/revoke authorization; `requesting_application` set from `doorkeeper_token.application.application`; subject resolved from explicit `subject_type` + `character_lodestone_id` params (see API subject resolution below)

---

## Implementation Sequence

1. Migration (single: `create_pki_tables`) → `Pki::CertificateAuthority` + `Pki::IssuedCertificate` models + specs
2. `Pki::IssuancePolicy` module + specs
3. `CharacterRegistration` + `User` association changes + callback specs
4. `Pki::CertificateIssuanceService` + specs (stub `Pki::CertificateAuthority.current_for` in tests)
5. `Certificates::OcspController` + specs
6. `Certificates::CrlsController` (stubbed — empty CRL) + specs
7. `Certificates::RootsController` + views (public, read-only)
8. `CertificatesController` (UI) + views
9. `Api::V1::CertificatesController` — subject resolved from `subject_type` (`"user"` or `"character"`) + `character_lodestone_id` params; `requesting_application` from `doorkeeper_token.application.application`
10. Routes + `ability.rb`
11. `pki:generate_ca` rake task
