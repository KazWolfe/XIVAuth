class CharacterMailer < Devise::Mailer
  include PostmarkRails::TemplatedMailerMixin
  include Devise::Controllers::UrlHelpers
  default from: 'noreply@xivauth.net'

  def security_character_verified_elsewhere(character)
    self.template_model = {
      username: character.user.name,
      lodestone_url: helpers.lodestone_url(character),
      character_name: character.character_name
    }

    mail to: character.user.email,
         from: 'XIVAuth Security <security@xivauth.net>',
         postmark_template_alias: 'secalert-character-verified-elsewhere'
  end
end
