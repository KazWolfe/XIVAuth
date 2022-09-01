Sidekiq.configure_server do |config|
  config.redis = {
    url: "#{ENV['REDIS_URL']}/12",
    password: ENV.fetch('REDIS_PASSWORD') { nil }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "#{ENV['REDIS_URL']}/12",
    password: ENV.fetch('REDIS_PASSWORD') { nil }
  }
end