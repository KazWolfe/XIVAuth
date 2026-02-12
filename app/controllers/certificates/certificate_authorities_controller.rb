class Certificates::CertificateAuthoritiesController < ApplicationController
  layout :set_layout
  skip_before_action :authenticate_user!

  def index
    @certificate_authorities = PKI::CertificateAuthority.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json
    end
  end

  def show
    @certificate_authority = PKI::CertificateAuthority.find_by!(slug: params[:slug])

    respond_to do |format|
      format.pem  { send_data @certificate_authority.certificate_pem,
                              type: "application/x-pem-file", disposition: "inline" }
      format.der  { send_data OpenSSL::X509::Certificate.new(@certificate_authority.certificate_pem).to_der,
                              type: "application/pkix-cert", disposition: "inline" }

      # default to PEM for compatibility. HTML still renders the page.
      format.any  { send_data @certificate_authority.certificate_pem,
                              type: "application/x-pem-file", disposition: "inline" }
    end
  end

  private def set_layout
    user_signed_in? ? "portal/page" : "marketing/page"
  end
end
