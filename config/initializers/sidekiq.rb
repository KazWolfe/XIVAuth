index = ENV.fetch('REDIS_DB_INDEX') { 12 }

Sidekiq.configure_server do |config|
  config.redis = {
    url: "#{ENV['REDIS_URL']}/#{index}",
    password: ENV.fetch('REDIS_PASSWORD') { nil }
  }

  config.on(:startup) do
    if File.exist?((schedule_file = 'config/cron.yml'))
      Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "#{ENV['REDIS_URL']}/#{index}",
    password: ENV.fetch('REDIS_PASSWORD') { nil }
  }
end