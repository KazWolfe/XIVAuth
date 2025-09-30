class Team::Profile < ApplicationRecord
  belongs_to :team, class_name: "Team", inverse_of: :profile

  def avatar_url
    super || "https://api.dicebear.com/9.x/icons/png?seed=#{team.name}"
  end
end