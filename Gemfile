source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby ">= 3.4.0", "< 3.5"

# Rails.
gem "rails", "~> 8.0.0"

# Core systems
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "redis", "~> 5.2"

# Platform-specific
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Frontend/Pipeline things
gem "cssbundling-rails"
gem "jsbundling-rails"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails"

# JSON API
gem "jbuilder"

# Performance
gem "bootsnap", require: false

# Mail Services
gem "postmark-rails", "~> 0.22.1"

# Internal Security
gem "rack-cors", "~> 2.0.2"

# Workers
gem "sidekiq", "~> 7.3.0"
gem "sidekiq-cron", "~> 2.0.1"
gem "sidekiq-throttled", "~> 1.5.0"
gem "sidekiq-unique-jobs", "~> 8.0.10"

# Authentication / Authorization
gem "cancancan", "~> 3.5"
gem "devise", "~> 4.9"
gem "devise_zxcvbn", "~> 6.0.0"

# Authn (MFA)
gem "devise-two-factor", "~> 6.1"
gem "rqrcode", "~> 2.2.0"
gem "webauthn", "~> 3.2.0"

# OAuth2 Providers
gem "omniauth-github", "~> 2.0.1"
gem "omniauth-oauth2", "~> 1.8.0"
gem "omniauth-steam", "~> 1.0.6"
gem "omniauth-twitch", "~> 1.2.0"

# Outbound OAuth2
gem "doorkeeper", "~> 5.8.0"
gem "doorkeeper-device_authorization_grant", "~> 1.0.3"

# Feature flags
gem "flipper", "~> 1.3"
gem "flipper-active_record", "~> 1.3"
gem "flipper-ui", "~> 1.3"

# Internal security
gem "jwt", "~> 2.9.0"
gem "omniauth-rails_csrf_protection", "~> 1.0.1"
gem "rbnacl", "~> 7.1.1"
gem "recaptcha", "~> 5.17"

# HTTP Requests
gem "faraday", "~> 2.9"

# Better logging
gem "rails_semantic_logger", "~> 4.17"

# Observability (Sentry) - temp for now
gem "sentry-rails", "~> 5.18"
gem "sentry-ruby", "~> 5.18"
gem "sentry-sidekiq", "~> 5.18"
gem "stackprof", "~> 0.2"

# Heroku dependencies
gem "rexml", "~> 3.3.1"

# Helpers
gem "pagy", "~> 9.3"

group :production do
  # Handle Cloudflare IPs in our X-Forwarded-For chain
  gem "cloudflare-rails", "~> 6.0"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "amazing_print"

  gem "factory_bot_rails", "~> 6.4.3"
  gem "faker", "~> 3.4"
  gem "rspec-rails", "~> 7.1"

  # Analysis tools
  gem "brakeman", require: false

  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
