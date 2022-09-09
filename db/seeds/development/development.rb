# frozen_string_literal: true

require 'factory_bot_rails'

# Create a dev user so I have some data to play with
devuser = User.create!(
  username:              'dev',
  email:                 'dev@eorzea.id',
  password:              'password',
  password_confirmation: 'password',
  confirmed_at:          Time.now
)

Oauth::ClientApplication.create(
  owner: devuser,
  name: 'XIVAuth Dev Client App',
  redirect_uri: 'http://localhost:3030/oauth/redirect',
  scopes: 'refresh character:manage user',
  uid: '2E-ttyhWBuLLOk00oo0HUaPUtdbyBpbp23jFKpxBPto',
  secret: 'BozYQ8gqo-Lcg-DNliKet2JGCI4RbdweHvbQKAfC7ow'
)

# some fake users/characters
3.times do
  FactoryBot.create(:random_character)
  next
end
