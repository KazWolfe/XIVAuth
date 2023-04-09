json.extract! character_registration, :id
json.character do
  json.extract! character_registration.character, :lodestone_id, :content_id, :name,
                :home_world, :data_center, :avatar_url, :portrait_url
  json.refreshed_at character_registration.character.updated_at
end

json.extract! character_registration, :verified_at, :verification_key

json.extract! character_registration, :created_at, :updated_at

json._url character_registration_url(character_registration, format: :json)