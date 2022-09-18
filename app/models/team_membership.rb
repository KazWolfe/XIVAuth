class TeamMembership < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :team, touch: true

  validates :role, presence: true, uniqueness: { scope: :team_id }, if: -> { role == :owner }

  enum role: {
    owner: 'owner',
    admin: 'admin',
    developer: 'developer',
    user: 'user'
  }
end
