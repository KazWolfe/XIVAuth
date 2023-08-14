class UserMailer < Devise::Mailer
  include PostmarkRails::TemplatedMailerMixin
  include Devise::Controllers::UrlHelpers
  default from: 'XIVAuth <noreply@xivauth.net>'

  def reset_password_instructions(record, token, opts = nil)
    self.template_model = {
      email: record.email,
      action_url: edit_password_url(record, reset_password_token: token),
      new_reset_url: new_user_password_url,
      link_ttl: Devise.reset_password_within.inspect
    }

    mail to: record.email, postmark_template_alias: 'password-reset'
  end

  def confirmation_instructions(record, token, opts = nil)
    if record.pending_reconfirmation?
      reconfirmation_instructions(record, token, opts)
      return
    end

    self.template_model = {
      email: record.email,
      action_url: confirmation_url(record, confirmation_token: token)
    }

    mail to: record.email, postmark_template_alias: 'welcome'
  end

  def reconfirmation_instructions(record, token, opts = nil)
    self.template_model = {
      email: record.unconfirmed_email,
      action_url: confirmation_url(record, confirmation_token: token)
    }

    mail to: record.unconfirmed_email, postmark_template_alias: 'reconfirmation'
  end
end
