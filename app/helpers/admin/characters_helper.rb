module Admin::CharactersHelper
  def link_to_lodestone(text, character, region = 'na')
    link_to text, lodestone_url(character, region)
  end
  
  def lodestone_url(character, region = 'na')
    "https://#{region}.finalfantasyxiv.com/lodestone/character/#{character.lodestone_id}/"
  end
end
