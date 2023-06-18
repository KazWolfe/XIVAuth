class OAuth::PermissiblePolicy < ApplicationRecord
  has_many :entries, class_name: 'OAuth::PermissibleEntry', dependent: :destroy
end
