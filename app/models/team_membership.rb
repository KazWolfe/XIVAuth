class TeamMembership < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :team, touch: true

  enum role: {
    owner: "owner",
    admin: "admin",
    developer: "developer",
    user: "user"
  }
end
