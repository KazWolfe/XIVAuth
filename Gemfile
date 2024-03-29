source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.0.7'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem 'jsbundling-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem 'cssbundling-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Mail Services
gem 'postmark-rails', '~> 0.22.1'

# Internal Security
gem 'rack-cors', '~> 2.0.1'

# Workers
gem 'sidekiq', '~> 7.1.0'
gem 'sidekiq-cron', '~> 1.10.0'

# Authentication / Authorization
gem 'cancancan', '~> 3.5'
gem 'devise', '~> 4.9'
gem 'devise_zxcvbn', '~> 6.0.0'

# Authn (MFA)
gem 'devise-two-factor', '~> 5.0.0'
gem 'rqrcode', '~> 2.1.2'
gem 'webauthn', '~> 3.0.0'

# OAuth2 Providers
gem 'omniauth-github', '~> 2.0.1'
gem 'omniauth-oauth2', '~> 1.8.0'
gem 'omniauth-steam', '~> 1.0.6'
gem 'omniauth-twitch', '~> 1.2.0'

# Outbound OAuth2
gem 'doorkeeper', '~> 5.6.6'
gem 'doorkeeper-device_authorization_grant', '~> 1.0.3'

# Feature flags
gem 'flipper', '~> 0.28.0'
gem 'flipper-active_record', '~> 0.28.0'
gem 'flipper-ui', '~> 0.28.0'

# Internal security
gem 'jwt', '~> 2.7.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0.1'
gem 'rbnacl', '~> 7.1.1'
gem 'recaptcha', '~> 5.14.0'

# HTTP Requests
gem 'faraday', '~> 2.7'

# Better logging
gem 'rails_semantic_logger', '~> 4.12'

# Observability (Sentry) - temp for now
gem 'sentry-rails', '~> 5.9.0'
gem 'sentry-ruby', '~> 5.9.0'
gem 'stackprof', '~> 0.2.25'

# Heroku dependencies
gem 'rexml', '~> 3.2.5'

group :production do
  # Handle Cloudflare IPs in our X-Forwarded-For chain
  gem 'cloudflare-rails', '~> 3.0.0'
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  gem 'amazing_print'

  gem 'factory_bot_rails', '~> 6.2.0'
  gem 'faker', '~> 3.2.0'
  gem 'rspec-rails', '~> 6.0.3'

  # Analysis tools
  gem 'brakeman', require: false
  gem 'rubocop', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem 'rack-mini-profiler'

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
