class Users::WebauthnAuthenticationsController < ApplicationController
  skip_before_action :authenticate_user!

  def challenge

  end
end
