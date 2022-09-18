# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # FIXME: Remove this, this is just testing.
    can [:manage], :all if user.admin?

    can [:read, :update, :verify, :destroy], Character, user: user
    can [:read, :update, :destroy], User, id: user.id

    can [:use], OAuth::ClientApplication, public: true
    can [:use, :manage], OAuth::ClientApplication, owner: user

  end
end
