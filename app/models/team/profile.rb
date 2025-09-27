class Team::Profile < ApplicationRecord
  belongs_to :team, class_name: "Team"
end