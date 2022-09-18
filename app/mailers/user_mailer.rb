class UserMailer < Devise::Mailer
  include PostmarkRails::TemplatedMailerMixin
  include Devise::Controllers::UrlHelpers
  default from: 'noreply@xivauth.net'

  def reset_password_instructions(record, token, opts = nil)
    self.template_model = {
      username: record.username,
      link_ttl: '12 hours'
    }
    
    mail to: record.email, postmark_template_alias: 'password-reset'
    super
  end

  def confirmation_instructions(record, token, opts = nil)
    reconfirmation_instructions(record, token, opts) and return if record.pending_reconfirmation?
    
    self.template_model = {
      username: record.username,
      confirm_url: confirmation_url(record, confirmation_token: token)
    }
    
    mail to: record.email, postmark_template_alias: 'welcome'
  end
  
  def reconfirmation_instructions(record, token, opts = nil)
    super.confirmation_instructions(record, token, opts)
  end
end
