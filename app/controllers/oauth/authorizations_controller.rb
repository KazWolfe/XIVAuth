class OAuth::AuthorizationsController < Doorkeeper::AuthorizationsController
  def create
    # Because we need everything to be condensed to a single form (HTML...), we're going to implement a bit of a dirty
    # hack here. If the disposition is set to "deny" (meaning the user clicked the deny button), we're going to pretend
    # that they submitted an HTTP DELETE like *what should happen*.
    (destroy and return) if params[:disposition] == "deny"

    Rails.logger.info "approved"
    super
  end

  def destroy
    Rails.logger.info "denied"
    super
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
      Character.where(user_id: current_user.id, id: characters)
    )

    unless policies.count > 0
      Rails.logger.warn 'No policies were created. This really should not happen, but continuing'
      return
    end

    policies[0].policy_id
  end
end
