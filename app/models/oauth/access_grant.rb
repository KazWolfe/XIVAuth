class Oauth::AccessGrant < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant
  self.table_name = "oauth_access_grants"

  has_many :oauth_permissibles, :class_name => 'Oauth::Permissible', 
           primary_key: :permissible_id, foreign_key: :policy_id
end
