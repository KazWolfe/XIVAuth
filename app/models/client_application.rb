class ClientApplication < ApplicationRecord
  belongs_to :owner, polymorphic: true, optional: true

  has_one :profile, class_name: "ClientApplication::Profile", dependent: :destroy, required: true, autosave: true,
          foreign_key: :application_id, inverse_of: :application

  has_many :oauth_clients, class_name: "ClientApplication::OAuthClient", dependent: :destroy,
           foreign_key: :application_id, inverse_of: :application
  # has_many :acls, class_name: "ClientApplication::AccessControlList", dependent: :destroy,
  #          foreign_key: :application_id, inverse_of: :application

  validates_associated :profile
  accepts_nested_attributes_for :profile, update_only: true

  def profile
    super || build_profile
  end

  def verified?
    self.verified_at.present?
  end
end