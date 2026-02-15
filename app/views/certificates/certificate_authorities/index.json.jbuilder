routes = Rails.application.routes.url_helpers

json.root_ca do
  json.name "rootca"
  json.fingerprint "8121ca12401c650e9dbc46a8a6381349195528d41e79c7be8e42146f67dc2dad"
  json.download do
    json.pem "https://pki.xivauth.net/rootca/67DC2DAD.crt"
    json.der "https://pki.xivauth.net/rootca/67DC2DAD.cer"
  end
end

json.issuing_cas @certificate_authorities do |ca|
  json.name ca.slug
  status = if ca.revoked?
             "revoked"
           elsif ca.active?
             "active"
           else
             "retired"
           end
  json.status status

  json.allowed_certificate_types ca.allowed_certificate_types
  json.expires_at ca.expires_at&.iso8601
  json.fingerprint ca.certificate_fingerprint.sub(/^\w+:/, "")
  json.download do
    json.pem routes.ca_cert_url(ca.slug, format: :pem)
    json.der routes.ca_cert_url(ca.slug, format: :der)
  end
end
