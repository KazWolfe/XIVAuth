# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md

    can :manage, CharacterRegistration, user_id: user.id

    can :use, OAuth::ClientApplication
    can :manage, OAuth::ClientApplication, owner: user

    can :manage, SocialIdentity, user_id: user.id
  end
end
