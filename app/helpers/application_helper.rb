module ApplicationHelper
  def dotiw_hover(timestamp)
    return 'Never' if timestamp.nil?

    "<span title=\"#{timestamp}\">#{distance_of_time_in_words_to_now(timestamp)} ago</span>".html_safe
  end
end
