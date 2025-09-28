class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, CharacterRegistration, user_id: user.id
    can :manage, User::SocialIdentity, user_id: user.id

    can :use, ClientApplication do |a|
      a.usable_by?(user)
    end

    can :manage, ClientApplication do |a|
      if a.owner.is_a?(User)
        a.owner == user
      elsif a.owner.is_a?(Team)
        a.owner.direct_memberships.developers.where(user_id: user.id).any? ||
        a.owner.antecedent_memberships.developers.where(user_id: user.id).any?
      else
        false
      end
    end

    can :show, Team do |t|
      t.direct_memberships.where(user_id: user.id).any? ||
      t.antecedent_memberships.where(user_id: user.id).any?
    end
  end
end
