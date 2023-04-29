class SocialIdentity < ApplicationRecord
  belongs_to :user, optional: true
  validates_uniqueness_of :external_id, scope: [:provider]
  validates_uniqueness_of :user_id, scope: [:provider, :external_id]

  alias_attribute :uid, :external_id

  def friendly_name
    name || nickname || email || external_id
  end

  # @param [OmniAuth::AuthHash] auth The AuthHash from OmniAuth
  def merge_auth_hash(auth, save_email: false)
    self.name = auth['info']['name']
    self.nickname = auth['info']['nickname']
    self.email = auth['info']['email'] || email if save_email

    save
  end
end
