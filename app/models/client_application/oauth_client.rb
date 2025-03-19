class ClientApplication::OAuthClient < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  self.table_name = "client_application_oauth_clients"  # HACK: Doorkeeper overrides this.

  belongs_to :application, class_name: "ClientApplication", touch: true

  alias_attribute :uid, :client_id
  alias_attribute :secret, :client_secret

  def redirect_uri
    self.redirect_uris.join("\n")
  end

  def redirect_uri=(val)
    if val.is_a?(String)
      val = val.split("\n")
    end
    self.redirect_uris = val
  end

  def active?
    self.enabled && !self.expired?
  end

  def expired?
    self.expires_at.present? && self.expires_at < Time.now
  end
end