source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby ">= 3.4.0", "< 3.5"

# Rails.
gem "rails", "~> 8.0.0"

# Core systems
gem "pg", "~> 1.5"
gem "puma", "~> 7.0"
gem "redis", "~> 5.2"

# Platform-specific
gem "tzinfo-data", platforms: %i[windows jruby]

# Frontend/Pipeline things
gem "cssbundling-rails"
gem "jsbundling-rails"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails"

# JSON API
gem "jbuilder"

# Performance
gem "bootsnap", require: false

# Mail Services
gem "postmark-rails", "~> 0.22.1"

# Internal Security
gem "rack-cors", "~> 3.0.0"

# Workers
gem "sidekiq", "~> 8.0"
gem "sidekiq-cron", "~> 2.3"
gem "sidekiq-throttled", "~> 2.0"
gem "sidekiq-unique-jobs", "~> 8.0.10"

# Authentication / Authorization
gem "cancancan", "~> 3.5"
gem "devise", "~> 4.9"
gem "devise_zxcvbn", "~> 6.0.0"

# Authn (MFA)
gem "devise-two-factor", "~> 6.1"
gem "rqrcode", "~> 3.1.0"
gem "webauthn", "~> 3.4.1"

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
gem "rails_cloudflare_turnstile", "~> 0.4"
gem "rbnacl", "~> 7.1.1"

# HTTP Requests
gem "faraday", "~> 2.9"

# Better logging
gem "rails_semantic_logger", "~> 4.17"

# Observability (OTel)
# gem "opentelemetry-instrumentation-faraday", "~> 0.24"
# gem "opentelemetry-instrumentation-rails", "~> 0.34"
# gem "opentelemetry-instrumentation-sidekiq", "~> 0.25"
# gem "opentelemetry-sdk", "~> 1.6"

# Observability (Sentry) - temp for now
# gem "sentry-opentelemetry", "~> 5.18"
gem "sentry-rails", "~> 5.18"
gem "sentry-ruby", "~> 5.18"
gem "sentry-sidekiq", "~> 5.18"
gem "stackprof", "~> 0.2"

# Heroku dependencies
gem "rexml", "~> 3.4.2"

# Helpers
gem "pagy", "~> 9.3"

group :production do
  # Handle Cloudflare IPs in our X-Forwarded-For chain
  gem "cloudflare-rails", "~> 6.0"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]

  gem "amazing_print"

  gem "factory_bot_rails", "~> 6.5"
  gem "faker", "~> 3.4"
  gem "rspec-rails", "~> 8.0"

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
