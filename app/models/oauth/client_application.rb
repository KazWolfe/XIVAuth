class Oauth::ClientApplication < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  self.table_name = "oauth_client_applications"

  belongs_to :owner, polymorphic: true
end
