class CharacterRegistrationMailer < ApplicationMailer
  include PostmarkRails::TemplatedMailerMixin

  # @param registration [CharacterRegistration] The character registration that was *invalidated*.
  def character_verified_elsewhere(registration)
    self.template_model = {
      username: registration.user.email,
      lodestone_url: registration.character.lodestone_url,
      character_name: registration.character.name
    }

    mail to: registration.user.email, postmark_template_alias: "secalert-character-verified-elsewhere"
  end
end
