class LegalController < ApplicationController
  skip_before_action :authenticate_user!

  layout :set_layout

  def terms_of_service; end
  def privacy_policy; end
  def developer_agreement; end
  def security_policy; end

  def moderation_policy; end

  private def set_layout
    user_signed_in? ? "portal/page" : "marketing/page"
  end
end
