require 'environment_info'

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :strict_dynamic, "https://challenges.cloudflare.com",
                       "https://static.cloudflareinsights.com"
    policy.style_src   :self, :https, :unsafe_inline

    if (csp_base_uri = Rails.application.credentials.dig(:sentry, :csp_report_uri))
      policy.report_uri csp_base_uri +
                        "&sentry_environment=#{EnvironmentInfo.environment}" +
                        "&sentry_release=#{EnvironmentInfo.commit_hash}"
    end
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = true
end
