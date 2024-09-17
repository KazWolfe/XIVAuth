json.extract! character, :lodestone_id, :name, :home_world, :data_center

json.extract! character, :content_id if @doorkeeper_token.scopes.exists? "character:manage"

json.extract! character, :avatar_url, :portrait_url
