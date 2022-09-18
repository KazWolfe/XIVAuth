module ApplicationHelper
  def link_to_lodestone(text, character, region = 'na')
    link_to text, "https://#{region}.finalfantasyxiv.com/lodestone/character/#{character.lodestone_id}/"
  end

  def verified_mark(verified, filled: true, title: '')
    html_class = "bi-patch-check#{'-fill' if filled}"

    verified ? " <i class=\"bi #{html_class} text-success\", title=\"#{title}\"></i>".html_safe : ''
  end

  def verifiable_text(text, verified, filled: true, title: '')
    # raiiiiiiils pls
    (h(text) + verified_mark(verified, filled:, title:)).html_safe
  end
  
  def dotiw_hover(timestamp)
    return 'Never' if timestamp.nil?
    
    "<span title=\"#{timestamp}\">#{distance_of_time_in_words_to_now(timestamp)} ago</span>".html_safe
  end
end
