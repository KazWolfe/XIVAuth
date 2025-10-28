module OAuth
  class AuthorizationsController < Doorkeeper::AuthorizationsController
    include OAuth::BuildsPermissiblePolicies

    def new
      pre_auth.validate  # need to validate first to populate info for preflight

      # Preflight checks
      @preflight = ::OAuth::PreflightCheck.new(pre_auth)

      unless @preflight.valid?
        render_preflight_error
        return
      end

      super
    end

    def create
      # Cheat to get around needing client-side JavaScript to submit a DELETE.
      # The actual DELETE method still works, so this is in addition to compliance, at least.
      (destroy and return) if params["disposition"] == "deny"

      super

      token = @authorize_response.auth.token
      if token.respond_to? :permissible_policy
        policy = build_permissible_policy
        if policy.rules.present?
          policy.save!

          token.permissible_policy = policy
          token.save!
        end
      end
    end

    private def render_preflight_error
      render :preflight_error, status: :bad_request
    end
  end
end
