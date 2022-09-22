class OAuth::AuthorizationsController < Doorkeeper::AuthorizationsController
  USER_FAULT_ERRORS = [:no_verified_characters].freeze

  def create
    # Thanks to the absolute pain that adding a character to dropdowns seemed to cause, we needed to edit how the :new
    # form works in order to only have a single form object. Because HTML is limited to only declaring a single action
    # in a form (and an external dependency on JS just for this seems like a bad idea), we're going to cheat a bit and
    # use a value to determine what button a user pressed. If they deny the request, shunt them over to the destroy
    # endpoint just like everything worked the way we expected.
    (destroy and return) if params[:disposition] == 'deny'

    super
  end
  
  private def render_error
    # Another little shim - if the error in question was caused by a user (rather than a system/configuration error on)
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
