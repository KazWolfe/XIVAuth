class Oauth::ClientApplication < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

  belongs_to :owner, polymorphic: true
end
