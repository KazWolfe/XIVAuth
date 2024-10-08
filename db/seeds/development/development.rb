# Create a user with a known ID for consistent verification
superuser = User.find_or_create_by!(email: "dev@eorzea.id") do |u|
  u.id = "e5854f0d-fdad-4a76-a208-ec682ec7ffb4"
  u.password = "password"
  u.roles = [:admin]
  u.build_profile(display_name: "developer")
  u.skip_confirmation!
end

OAuth::ClientApplication.find_or_create_by!(uid: "superapp") do |app|
  app.name = "Seeded Super App"
  app.owner = superuser
  app.confidential = true
  app.secret = "superapp_6663def85024"
  app.redirect_uri = "http://127.0.0.1:3030/oauth/redirect"
  app.scopes = Doorkeeper.configuration.scopes
end

JwtSigningKeys::RSA.find_or_create_by(name: "dev_rsa")
JwtSigningKeys::Ed25519.find_or_create_by(name: "dev_ed25519")
JwtSigningKeys::HMAC.find_or_create_by(name: "dev_hmac")
