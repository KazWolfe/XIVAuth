class ClientApplication::AccessControlList < ApplicationRecord
  belongs_to :application, class_name: "ClientApplication"
end