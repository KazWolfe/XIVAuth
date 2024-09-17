class Users::PasswordsController < Devise::PasswordsController
  helper Users::SessionsHelper

  prepend_before_action :check_captcha, only: [:create]

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    super
  end

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

  private def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new

    flash.discard(:recaptcha_error)
    render :new, status: :unprocessable_entity
  end
end
