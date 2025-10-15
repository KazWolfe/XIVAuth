require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.eager_load_paths << Rails.root.join("lib/contextual_logger")

    # don't log to file by default.
    config.rails_semantic_logger.add_file_appender = false

    config.action_controller.include_all_helpers = false

    # Better error pages
    config.exceptions_app = lambda { |env|
      ErrorsController.action(:show).call(env)
    }

    config.action_dispatch.rescue_responses["CanCan::AccessDenied"] = :unauthorized

    # heroku compat for now
    if ENV["APP_ENV"].present?
      Rails.application.config.credentials.content_path = Rails.root.join("config/credentials/#{ENV['APP_ENV']}.yml.enc")
    end

    config.generators do |generate|
      generate.orm :active_record, primary_key_type: :uuid
    end
  end
end
