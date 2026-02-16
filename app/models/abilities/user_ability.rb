class Abilities::UserAbility
  include CanCan::Ability

  def initialize(user)
    can :manage, CharacterRegistration, user_id: user.id
    can :manage, User::SocialIdentity, user_id: user.id

    can :use, ClientApplication do |a|
      a.usable_by?(user)
    end

    can :manage, ClientApplication do |a|
      if a.owner.is_a?(User)
        a.owner_id == user.id
      elsif a.owner.is_a?(Team)
        a.owner.direct_memberships.developers.where(user_id: user.id).any? ||
          a.owner.antecedent_memberships.developers.where(user_id: user.id).any?
      else
        false
      end
    end

    can :show, Team do |t|
      t.direct_memberships.active.where(user_id: user.id).any? ||
        t.antecedent_memberships.where(user_id: user.id).any?
    end

    can :manage, Team do |t|
      t.direct_memberships.admins.where(user_id: user.id).any? ||
        t.antecedent_memberships.admins.where(user_id: user.id).any?
    end

    can :create_apps, Team do |t|
      t.direct_memberships.developers.where(user_id: user.id).any? ||
        t.antecedent_memberships.developers.where(user_id: user.id).any?
    end

    # PKI certificates: read and revoke own certs.
    # User-subject certs: simple column condition.
    can %i[read revoke], PKI::IssuedCertificate, subject_type: "User", subject_id: user.id

    # CharacterRegistration-subject certs: block check (no simple hash condition due to polymorphic subject).
    can %i[read revoke], PKI::IssuedCertificate do |cert|
      cert.subject_type == "CharacterRegistration" &&
        user.character_registrations.verified.exists?(id: cert.subject_id)
    end
  end
end
