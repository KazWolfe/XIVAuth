class OAuth::TokensController < Doorkeeper::TokensController

  private def after_successful_authorization(context)
    super

    access_grant = strategy.request.grant
    access_token = context.auth.token

    # copy permissible (if it exists)
    access_token.permissible_id = access_grant.permissible_id if access_grant.permissible_id.present?
    access_token.save!
  end
end
