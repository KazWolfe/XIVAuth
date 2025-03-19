# Create a user with a known ID for consistent verification
superuser = User.find_or_create_by!(email: "dev@eorzea.id") do |u|
  u.id = "e5854f0d-fdad-4a76-a208-ec682ec7ffb4"
  u.password = "password"
  u.roles = [:admin]
  u.build_profile(display_name: "developer")
  u.skip_confirmation!
end

client_app = ClientApplication.find_or_create_by(name: "Seeded Super App") do |app|
  app.owner = superuser
  app.private = false
end

client_app.oauth_clients.find_or_create_by!(client_id: "superapp") do |client|
  client.name = "Seeded auth_code Client"
  client.client_secret = "superapp_6663def85024"
  client.confidential = true
  client.redirect_uri = "http://127.0.0.1:3030/oauth/redirect"
  client.scopes = Doorkeeper.configuration.scopes
end

JwtSigningKeys::RSA.find_or_create_by(name: "dev_rsa")
JwtSigningKeys::Ed25519.find_or_create_by(name: "dev_ed25519")
JwtSigningKeys::HMAC.find_or_create_by(name: "dev_hmac")
