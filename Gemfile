source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Core Rails Dependencies
gem 'rails', '~> 7.0.3', '>= 7.0.3.1'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'sprockets-rails'  # asset pipeline

# Frontend-ish
gem 'importmap-rails'
gem 'jbuilder'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'sassc-rails'

# Frontend utils
gem 'bootstrap', '~> 5.2.0'
# gem "font-awesome-sass", "~> 6.2.0"

# Workers
gem 'sidekiq'
gem "redis", "~> 4.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Outbound HTTP requests
gem 'rest-client'

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
gem 'omniauth-steam'
gem 'omniauth-github', '~> 2.0.0'
gem 'omniauth-rails_csrf_protection'

# Authentication and providers (outbound)
gem 'doorkeeper'
gem 'doorkeeper-openid_connect'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

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
  gem 'web-console'
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
