module ApplicationHelper
  def dotiw_hover(timestamp)
    return "Never" if timestamp.nil?

    "<span title=\"#{timestamp}\">#{distance_of_time_in_words_to_now(timestamp)} ago</span>".html_safe
  end

  def commit_hash
    ENV["COMMIT_HASH"] || ENV["RAILWAY_GIT_COMMIT_SHA"] || ENV["HEROKU_SLUG_COMMIT"] || nil
  end

  def hosting_provider
    if ENV["HEROKU_APP_NAME"]
      :heroku
    elsif ENV["RAILWAY_SERVICE_ID"]
      :railway
    elsif ENV["container"] == "podman"
      :podman
    else
      nil
    end
  end

  def lower_environment?
    !Rails.env.production? || (ENV["APP_ENV"] != "production")
  end
end
