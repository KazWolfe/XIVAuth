class OAuth::AuthorizationsController < Doorkeeper::AuthorizationsController
  USER_FAULT_ERRORS = [:no_verified_characters].freeze
  
=begin
  def new
    if pre_auth.scopes.include?('character') && !current_user.characters.verified.count.positive?
      # We actually have this at a lower level as well but this creates a nicer message for the user.
      @pre_auth.error = :no_verified_characters
      render :user_error and return
    end

    super
  end
=end

  def create
    # Because we need everything to be condensed to a single form (HTML...), we're going to implement a bit of a dirty
    # hack here. If the disposition is set to "deny" (meaning the user clicked the deny button), we're going to pretend
    # that they submitted an HTTP DELETE like *what should happen*. Stupid Turbo.
    (destroy and return) if params[:disposition] == 'deny'

    Rails.logger.info 'approved'
    super
  end

  def destroy
    Rails.logger.info 'denied'
    super
  end

  private def render_error
    # user-caused errors get treated a bit differently
    render :user_error and return if USER_FAULT_ERRORS.include? pre_auth.error
    
    super
  end

  def pre_auth
    # NOTE: Might look like the same code as the parent class, but this calls *our* pre-auth so that we can "improve"
    # it to better serve our purposes.
    @pre_auth ||= OAuth::PreAuthorization.new(
      Doorkeeper.configuration,
      pre_auth_params,
      current_resource_owner
    )
  end

  private def after_successful_authorization(context)
    # We're going to hijack the after_successful_authorization system to inject our permissibles. There probably is a
    # better place to do this, but this is fine, probably.
    super

    access_grant = context.auth.auth.token

    if access_grant.permissible_id.nil? and (access_grant.scopes & ["character"]).count > 0
      access_grant.permissible_id = create_policy_for_characters(params[:characters])
      access_grant.save!
    end
  end

  def create_policy_for_characters(characters)
    policies = OAuth::Permissible.create_policy_for_resources(
      Character.where(user_id: current_resource_owner.id, id: characters)
    )

    unless policies.count.positive?
      Rails.logger.warn 'No policies were created. This really should not happen, but continuing'
      return
    end

    policies[0].policy_id
  end
end
