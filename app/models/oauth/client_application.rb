class OAuth::ClientApplication < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  self.table_name = 'oauth_client_applications'

  validates :name, presence: true
  validates :redirect_uri, presence: true
  
  belongs_to :owner, polymorphic: true
end
