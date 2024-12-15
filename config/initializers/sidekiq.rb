require "sidekiq/web"

index = ENV.fetch("SIDEKIQ_DB_INDEX", 12)

Sidekiq::Web.app_url = "/"

Sidekiq.configure_server do |config|
  redis_settings = {
    url: "#{ENV['REDIS_URL']}/#{index}",
    password: ENV.fetch("REDIS_PASSWORD", nil)
  }

  redis_settings[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if Rails.env.production?

  config.redis = redis_settings

  config.on(:startup) do
    if File.exist?((schedule_file = "config/cron.yml"))
      Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
    end
  end
end

Sidekiq.configure_client do |config|
  redis_settings = {
    url: "#{ENV['REDIS_URL']}/#{index}",
    password: ENV.fetch("REDIS_PASSWORD", nil)
  }

  redis_settings[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if Rails.env.production?

  config.redis = redis_settings
end
