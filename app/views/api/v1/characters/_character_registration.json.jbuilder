if @doorkeeper_token.scopes.exists? "character:manage"
  json.__crid character_registration.id
  json.__cid character_registration.character.id
end

json.persistent_key character_registration.entangled_id

json.partial!("api/v1/characters/ffxiv_character", character: character_registration.character)

if @doorkeeper_token.scopes.exists? "character:manage"
  json.verified character_registration.verified_at.present?
  json.extract! character_registration, :verification_key
end

json.extract! character_registration, :created_at, :verified_at
json.updated_at [character_registration.updated_at, character_registration.character.updated_at].max
