class ClientApplication::Profile < ApplicationRecord
  belongs_to :application, class_name: "ClientApplication", touch: true

  def icon_url
    super || "https://ui-avatars.com/api/?name=#{application.name}&background=random"
  end
end