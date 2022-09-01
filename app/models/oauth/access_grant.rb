class Oauth::AccessGrant < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant
end
