# frozen_string_literal: true

class Api::V1::ApiController < ActionController::API
  # There are no "open" API calls; everything must require at least authorization.
  before_action :doorkeeper_authorize!
  before_action :load_token

  respond_to :json

  def current_user
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end

  private

  def check_resource_owner_presence
    render status: :unauthorized unless (current_user.present? && current_user.persisted?)
  end

  def load_token
    @doorkeeper_token = doorkeeper_token
  end
end
