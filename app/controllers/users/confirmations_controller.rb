class Users::ConfirmationsController < Devise::ConfirmationsController
  helper Users::SessionsHelper

  prepend_before_action :check_captcha, only: [:create]

  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  def create
    super
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end

  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new

    flash.discard(:recaptcha_error)
    render :new, status: :unprocessable_entity
  end
end
