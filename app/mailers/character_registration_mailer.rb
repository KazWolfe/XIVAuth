class CharacterRegistrationMailer < ApplicationMailer
  include PostmarkRails::TemplatedMailerMixin

  # @param registration [CharacterRegistration] The character registration that was *invalidated*.
  def character_verified_elsewhere
    registration = params[:registration]

    self.template_model = {
      display_name: registration.user.display_name,
      character_name: registration.character.name,
      character_world: registration.character.home_world,
      character_lodestone_url: registration.character.lodestone_url,
      character_management_route: character_registrations_url
    }

    mail to: registration.user.email, postmark_template_alias: "secalert-character-verified-elsewhere"
  end
end
