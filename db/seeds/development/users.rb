require 'factory_bot_rails'

# Create a dev user for me
User.create!(
  :username              => "KazWolfe",
  :email                 => "hi@wolf.dev",
  :password              => "password",
  :password_confirmation => "password",
  :confirmed_at          => Time.now
)

# some fake users/characters
3.times do
  FactoryBot.create(:random_character)
  next
end
