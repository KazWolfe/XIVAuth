class Developer::DeveloperPortalController < ApplicationController
  before_action :check_developer_role

  private def check_developer_role
    unless current_user.role?(:developer)
      redirect_to developer_onboarding_path
    end
  end
end