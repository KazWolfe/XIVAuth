module CharactersHelper
  LODESTONE_URL_REGEX = %r{(https?://(?<region>[a-z]{2})\.finalfantasyxiv\.com/lodestone/character/)?(?<lodestone_id>\d+)}

  def extract_id(id_or_url)
    if (res = LODESTONE_URL_REGEX.match(id_or_url))
      res['lodestone_id']
    end
  end

end
