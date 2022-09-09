require 'rails_helper'

RSpec.describe TeamMembership, type: :model do
  it 'returns a proper number of team members for a team' do
    team = FactoryBot.create(:random_team)

    3.times do
      FactoryBot.create(:random_team_membership, team: team)
    end

    expect(team.users.count).to eq(3)
  end

  it 'returns a proper number of teams for a user' do
    user = FactoryBot.create(:random_user)

    3.times do
      FactoryBot.create(:random_team_membership, user: user)
    end

    expect(user.teams.count).to eq(3)
  end

  it 'does not return users not belonging to that team' do
    team_membership = FactoryBot.create(:random_team_membership)
    another_user = FactoryBot.create(:random_team)

    expect(team_membership.team.users).to_not include(another_user)
  end

  it 'does not return teams not belonging to that user' do
    team_membership = FactoryBot.create(:random_team_membership)
    another_team = FactoryBot.create(:random_team)

    expect(team_membership.user.teams).to_not include(another_team)
  end

  it 'allows users to be added to a team' do
    team = FactoryBot.create(:random_team)
    user = FactoryBot.create(:random_user)

    expect(team.users).to_not include(user)
    TeamMembership.create(team: team, user: user, role: :admin)
    # team.users.reload
    expect(team.users).to include(user)
  end

  it 'allows users to be removed from a team' do
    team = FactoryBot.create(:random_team)
    user = FactoryBot.create(:random_user)
    FactoryBot.create(:random_team_membership, team: team) # make a membership but dont care about it (integrity)
    TeamMembership.create(team: team, user: user, role: :admin)

    expect(team.users).to include(user)
    TeamMembership.find_by(user_id: user.id, team_id: team.id).destroy
    expect(team.users).to_not include(user)
  end
end
