class LegalController < ApplicationController
  skip_before_action :authenticate_user!

  def terms_of_service; end
  def privacy_policy; end
  def developer_agreement; end
  def security_policy; end
end
