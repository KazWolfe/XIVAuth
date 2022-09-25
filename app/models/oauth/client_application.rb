class OAuth::ClientApplication < ActiveRecord::Base
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  self.table_name = 'oauth_client_applications'

  validates :name, presence: true
  validates :redirect_uri, presence: true

  belongs_to :owner, polymorphic: true

  before_destroy :destroy_safety_checks

  def pairwise_key
    super.present? ? super : self.id
  end

  private

  def destroy_safety_checks
    raise ActiveRecord::RecordNotDestroyed, 'Cannot delete a verified application!' if verified?
  end
end
