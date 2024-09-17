class OAuth::ClientApplication < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

  # Breaking name for convention - making it clear that these are applications created by clients.
  self.table_name = "oauth_client_applications"
end
