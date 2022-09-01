# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # FIXME: Remove this, this is just testing.
    can [:manage], :all if user.id == 1

    can [:read, :update, :verify, :destroy], Character, user: user
    can [:read, :update, :destroy], User, id: user.id

    can [:use], Oauth::ClientApplication, public: true
    can [:use, :manage], Oauth::ClientApplication do |application|
      if application.owner_type == "User"
        application.owner_id == user.id
      elsif application.owner_type == "Team"
        application.owner.team_memberships
                   .where(role: :owner).pluck(:user_id).include?(user.id)
      else
        # failsafe
        false
      end
    end


  end
end
