class Ability
  include CanCan::Ability

  def initialize(user)
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md

    can :manage, CharacterRegistration, user_id: user.id

    can :use, ClientApplication
    can :manage, ClientApplication, owner_id: user.id

    can :manage, User::SocialIdentity, user_id: user.id
  end
end
