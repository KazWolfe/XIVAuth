json.extract! social_identity, :provider, :external_id, :name, :nickname

if doorkeeper_token[:scopes].include?('user:email')
  json.extract! social_identity, :email
end

json.extract! social_identity, :created_at, :updated_at
