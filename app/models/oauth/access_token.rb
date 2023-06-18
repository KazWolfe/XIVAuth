class OAuth::AccessToken < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken

  # The permissible policy associated with this access token. Can be null if there's no policy.
  # Will be destroyed alongside this access token (slight smell - this is used elsewhere *but* this is the only model
  # that will persist).
  belongs_to :permissible_policy, class_name: 'OAuth::PermissiblePolicy', optional: true, dependent: :destroy
end
