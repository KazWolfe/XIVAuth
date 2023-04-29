source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Core Rails Dependencies
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.3', '>= 7.0.3.1'
gem 'redis', '~> 4.0'
gem 'sprockets-rails'  # asset pipeline

# Heroku?
gem 'rexml', "~> 3.2.5"

# Frontend-ish
gem 'importmap-rails'
gem 'jbuilder'
gem 'stimulus-rails'
gem 'sassc-rails'
gem 'turbo-rails'

# Frontend utils
gem 'bootstrap', '~> 5.2.0'
# gem "font-awesome-sass", "~> 6.2.0"

# Workers
gem 'sidekiq', '~> 6.5.6'
gem 'sidekiq-cron', '~> 1.7.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Outbound integrations
gem 'rest-client', '~> 2.1.0'
gem 'xivapi', git: 'https://github.com/xivapi/xivapi-ruby.git', tag: 'v0.3.3'

# Mail Services
gem 'postmark-rails'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Better logging
gem 'rails_semantic_logger'

# Authentication and providers (inbound)
gem 'cancancan'
gem 'devise'
gem 'devise_zxcvbn'
gem 'omniauth-discord'
gem 'omniauth-github', '~> 2.0.0'
gem 'omniauth-steam'

# Authn (MFA)
gem 'devise-two-factor', '~> 5.0.0'
gem "rqrcode", "~> 2.0"
gem 'webauthn', '~> 2.5.2'

# Internal security
gem 'jwt', '~> 2.5.0'
gem 'omniauth-rails_csrf_protection'
gem 'recaptcha', '~> 5.12.3'

# OAuth2 provider systems
gem 'doorkeeper'
gem 'doorkeeper-device_authorization_grant', '1.0.1'   # need fixed version, we will be patching this!
gem 'doorkeeper-openid_connect'

group :development, :test do
  gem 'debase', '0.2.5beta2'
  gem 'ruby-debug-ide'

  # Test harnesses
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'

  # Formatting annoyances
  gem 'rubocop'

  # Better logging, part 2
  gem 'amazing_print'
end

group :development do
  gem 'rack-mini-profiler'
  gem 'web-console'

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
