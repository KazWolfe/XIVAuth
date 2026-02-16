class Abilities::ClientAppAbility
  include CanCan::Ability

  def initialize(application)
    # NOTE: Application ability to see any given certificate is checked in the controller.

    # Open to all apps — no entitlement required
    can [:issue, :revoke], PKI::IssuancePolicy::UserIdentificationPolicy
    can [:issue, :revoke], PKI::IssuancePolicy::CharacterIdentificationPolicy

    # Restricted — requires explicit entitlement grant
    if application&.has_entitlement?("code_signing_certificates")
      can [:issue, :revoke], PKI::IssuancePolicy::CodeSigningPolicy
    end
  end
end
