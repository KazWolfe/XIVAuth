class OAuth::AccessToken < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
  self.table_name = "oauth_access_tokens"

  has_many :oauth_permissibles, :class_name => 'OAuth::Permissible',
           primary_key: :permissible_id, foreign_key: :policy_id, dependent: :delete_all


  def self.matching_token_for(application, resource_owner, scopes)
    # If the scopes require users select characters, don't match - the user will need to explicitly select
    # new choices.
    return nil if (scopes & %w[character character:all]).count > 0

    super
  end
end
