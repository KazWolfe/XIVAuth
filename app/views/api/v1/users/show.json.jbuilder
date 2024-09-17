json.extract! @user, :id

if @doorkeeper_token.scopes.exists?("user:email")
  json.email @user.email
  json.email_verified @user.confirmed_at.present? # basically always true
end

if @social_identities.present?
  json.social_identities @social_identities, partial: "api/v1/users/social_identity", as: "social_identity"
end

json.mfa_enabled @user.requires_mfa?
json.verified_characters @user.character_registrations.verified.count.positive?

json.created_at @user.created_at
json.updated_at @user.updated_at
