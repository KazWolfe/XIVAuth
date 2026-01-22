module ApplicationHelper
  def commit_hash
    EnvironmentInfo.commit_hash
  end

  def hosting_provider
    EnvironmentInfo.hosting_provider
  end

  def environment
    EnvironmentInfo.environment
  end

  def lower_environment?
    !Rails.env.production? || (ENV["APP_ENV"] != "production")
  end
end
