json.extract! @user, :id

if @doorkeeper_token[:scopes].include?('user:email')
  json.email @user.email
  json.email_verified @user.confirmed_at.present? # basically always true
end

if @doorkeeper_token[:scopes].include?('user:social')
  json.social_identities @user.social_identities, partial: 'api/v1/user/social_identity', as: 'social_identity', locals: {
    doorkeeper_token: @doorkeeper_token
  }
end

json.verified_characters @user.character_registrations.verified.count
