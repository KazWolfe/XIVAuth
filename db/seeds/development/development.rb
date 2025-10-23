superuser = User.find_or_create_by!(email: "dev@eorzea.id") do |u|
  # Use a consistent ID so that character PKs and verification codes are predictable, so long as SECRET_KEY_BASE is
  # the same.
  u.id = "00000000-0000-8000-8f00-fe55934cf9a0"
  u.password = "password"
  u.roles = [:admin]
  u.build_profile(display_name: "developer")
  u.skip_confirmation!
end

superteam = Team.find_or_create_by!(id: "00000000-0000-8000-8f0f-000000000001") do |t|
  t.name = "XIVAuth Developers"
  t.direct_memberships.build(user: superuser, role: "admin")
end

client_app = ClientApplication.find_or_create_by!(id: "00000000-0000-8000-8f00-ea9e0669f9ba") do |app|
  app.name = "XIVAuth Dev Client"
  app.owner = superteam
  app.private = false

  app.profile.homepage_url = "https://xivauth.net/"
end

client_app.oauth_clients.find_or_create_by!(client_id: "superapp") do |client|
  client.id = "00000000-0000-8000-8f00-6663def85024"
  client.name = "Seeded auth_code Client"
  client.client_secret = "superapp_6663def85024"
  client.confidential = true
  client.redirect_uri = "http://127.0.0.1:3030/oauth/redirect"
  client.scopes = Doorkeeper.configuration.scopes
end

JwtSigningKeys::RSA.find_or_create_by(name: "dev_rsa")
JwtSigningKeys::Ed25519.find_or_create_by(name: "dev_ed25519")
JwtSigningKeys::HMAC.find_or_create_by(name: "dev_hmac")
