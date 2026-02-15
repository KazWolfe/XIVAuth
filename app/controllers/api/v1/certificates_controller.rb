class Api::V1::CertificatesController < Api::V1::ApiController
  include Api::FiltersAuthorizedCharacters

  before_action :check_resource_owner_presence
  before_action :set_certificate, only: %i[show revoke]

  before_action(only: %i[index show]) { doorkeeper_authorize! "certificate", "certificate:all", "certificate:issue", "certificate:revoke", "certificate:manage" }
  before_action(only: %i[request_cert]) { doorkeeper_authorize! "certificate:issue", "certificate:manage" }
  before_action(only: %i[revoke]) { doorkeeper_authorize! "certificate:revoke", "certificate:manage" }

  def index
    @certificates = accessible_certificates.order(issued_at: :desc)
    render json: @certificates
  end

  def show
    render json: @certificate
  end

  # Params:
  #   csr_pem       [String] PEM-encoded CSR (required)
  #   subject_type  [String] "user" or "character" (required)
  #   lodestone_id  [String] Lodestone character ID (required when subject_type == "character")
  def request_cert
    subject = resolve_subject
    return unless subject

    service = PKI::CertificateIssuanceService.new(subject: subject)
    result = service.issue!(
      csr_pem: read_csr_pem,
      requesting_application: requesting_application
    )

    if result.is_a?(PKI::IssuedCertificate)
      render json: {
        id: result.id,
        certificate: result.certificate_pem,
        fingerprint: result.public_key_fingerprint.sub(/^\w+:/, "").scan(/../).join(":"),
        ca_url: ca_cert_url(result.certificate_authority.slug),
      }, status: :created

      # certificate was successfully issued, enable the certificates view in the UI.
      current_user.profile.set_feature_enabled!(:certificate_management, true)
    else
      # result is an invalid policy - return its errors
      render json: { errors: result.errors.full_messages }, status: :unprocessable_content
    end
  rescue PKI::CertificateAuthority::NoCertificateAuthorityError => e
    render json: { error: e.message }, status: :service_unavailable
  rescue PKI::CertificateIssuanceService::IssuanceError => e
    render json: { error: e.message }, status: :unprocessable_content
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  def revoke
    authorize! :revoke, @certificate

    reason = params.require(:reason).to_s
    unless PKI::IssuedCertificate::USER_REVOCATION_REASONS.include?(reason)
      return render json: { error: "Invalid revocation reason." }, status: :bad_request
    end

    @certificate.revoke!(reason: reason)
    render json: @certificate
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def set_certificate
    @certificate = accessible_certificates.find(params[:id])
    authorize! :read, @certificate
  end

  def resolve_subject
    case params[:subject_type]
    when "user"
      unless has_user_scope?
        render json: { error: "User scope required for certificate issuance" }, status: :forbidden
        return
      end

      current_user
    when "character"
      unless has_character_scope?
        render json: { error: "Character scope required for certificate issuance" }, status: :forbidden
        return
      end

      lodestone_id = params.require(:lodestone_id)

      return authorized_character_registrations(only_verified: true)
               .joins(:character)
               .find_by!(ffxiv_characters: { lodestone_id: lodestone_id })
    else
      render json: { error: "subject_type must be 'user' or 'character'" }, status: :bad_request
      nil
    end
  end

  # Return a list of certificates accessible in the current context.
  #
  # Unless certificate:all or certificate:manage is passed, only the certificates issued to *this application* will
  # be visible.
  #
  # Additionally, to access a certificate, this context *must* be able to see the subject associated with the
  # certificate as well. This applies even for `certificate:manage`.
  def accessible_certificates
    scope = PKI::IssuedCertificate.all

    unless has_certificate_all_scope?
      scope = scope.where(requesting_application: requesting_application)
    end

    conditions = []

    if has_user_scope?
      conditions << { subject_type: "User", subject_id: current_user.id }
    end

    if has_character_scope?
      authorized_character_ids = authorized_character_registrations(only_verified: true).pluck(:id)
      unless authorized_character_ids.empty?
        conditions << {
          subject_type: "CharacterRegistration",
          subject_id: authorized_character_ids
        }
      end
    end

    return scope.none if conditions.empty?

    conditions.reduce(scope.none) { |combined, condition| combined.or(scope.where(condition)) }
  end

  def has_certificate_all_scope?
    doorkeeper_token.scopes.exists?("certificate:all") ||
      doorkeeper_token.scopes.exists?("certificate:manage")
  end

  def has_user_scope?
    doorkeeper_token.scopes.exists?("user") || doorkeeper_token.scopes.exists?("user:manage")
  end

  def read_csr_pem
    param = params.require(:csr_pem)
    case param
    when ActionDispatch::Http::UploadedFile
      param.read
    when String
      param
    else
      raise ActionController::BadRequest, "csr_pem must be a PEM string or file upload"
    end
  end

  def requesting_application
    doorkeeper_token.application&.application
  end
end
