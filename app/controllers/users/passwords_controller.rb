# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  prepend_before_action :check_captcha, only: [:create]
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  private

  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new

    respond_with_navigational(resource) do
      # flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      redirect_to new_password_path(resource)
    end
  end
end
