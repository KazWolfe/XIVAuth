json.extract! @user, :id

if @doorkeeper_token.scopes.exists?('user:email')
  json.email @user.email
  json.email_verified @user.confirmed_at.present? # basically always true
end

if @doorkeeper_token.scopes.exists?('user:social')
  json.social_identities @user.social_identities, partial: 'api/v1/user/social_identity', as: 'social_identity'
end

json.verified_characters @user.character_registrations.verified.count.positive?

json.created_at @user.created_at
json.updated_at @user.updated_at