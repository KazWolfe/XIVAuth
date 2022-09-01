class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  enum role: {
    owner: "owner",
    admin: "admin",
    developer: "developer",
    user: "user"
  }
end
