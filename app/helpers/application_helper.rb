module ApplicationHelper
  def link_to_lodestone(text, character, region = "na")
    link_to text, "https://#{region}.finalfantasyxiv.com/lodestone/character/#{character.lodestone_id}/"
  end
end
