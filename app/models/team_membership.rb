class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team, touch: true

  validates :role, presence: true, uniqueness: { scope: :team_id }, if: -> { role == :owner }
  validates :role, presence: true

  enum role: {
    owner: 'owner',
    admin: 'admin',
    developer: 'developer',
    user: 'user'
  }
end
