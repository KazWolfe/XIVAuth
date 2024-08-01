module CharacterRegistrationsHelper
  include Pagy::Frontend

  # A stricter regex meant for validation on the browser side, where other constraints are at play.
  LODESTONE_CLIENT_FILTER_REGEX = %r{^((\d+)|(https?://)?[a-z]{2}\.finalfantasyxiv\.com/lodestone/character/\d+(/.*)?)$}

  # A more relaxed regex variant meant for just grabbing data from things.
  LODESTONE_URL_REGEX = %r{((https?://)?(?<region>[a-z]{2})\.finalfantasyxiv\.com/lodestone/character/)?(?<lodestone_id>\d+)/?}

  def extract_id(id_or_url)
    if (res = LODESTONE_URL_REGEX.match(id_or_url))
      res['lodestone_id']
    end
  end

  def can_add_characters?
    current_user.character_registrations.unverified.count < current_user.unverified_character_allowance
  end
end
