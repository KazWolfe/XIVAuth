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

OAuth::ClientApplication.create(
  owner: devuser,
  name: 'XIVAuth User/AllChar App',
  redirect_uri: 'http://localhost:3030/oauth/redirect',
  scopes: 'user user:email character character:all character:manage jwt refresh',
  grant_flows: %w[authorization_code device_code],
  uid: '7Ea0YN9n4Jh8bGXydexwaQiVfaVlRogmJ3Wi3CH6E8c',
  secret: 'uy6_MwmGWguFUqGmJZ1H-9TROP9eXQJlmux4orjDxQI'
)

# some fake users/characters
3.times do
  FactoryBot.create(:random_character)
  next
end
