index = ENV.fetch('REDIS_DB_INDEX') { 12 }

Sidekiq.configure_server do |config|
  config.redis = {
    url: "#{ENV['REDIS_URL']}/#{index}",
    password: ENV.fetch('REDIS_PASSWORD') { nil }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "#{ENV['REDIS_URL']}/#{index}",
    password: ENV.fetch('REDIS_PASSWORD') { nil }
  }
end