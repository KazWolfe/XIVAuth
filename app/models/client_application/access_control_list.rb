class ClientApplication::AccessControlList < ApplicationRecord
  belongs_to :application, class_name: "ClientApplication"
  belongs_to :principal, polymorphic: true
end