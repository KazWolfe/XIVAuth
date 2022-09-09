class Oauth::AccessToken < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
  self.table_name = "oauth_access_tokens"

  has_many :oauth_permissibles, :class_name => 'Oauth::Permissible',
           primary_key: :permissible_id, foreign_key: :policy_id
end
