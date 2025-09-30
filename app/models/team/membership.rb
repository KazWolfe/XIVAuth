class Team::Membership < ApplicationRecord
  enum :role, { admin: "admin", developer: "developer", member: "member", invited: "invited", blocked: "blocked" },
       scopes: false

  scope :admins, -> { where(role: [:admin]) }
  scope :developers, -> { where(role: %i[admin developer]) }
  scope :active, -> { where(role: %i[admin developer member]) }

  belongs_to :team, class_name: "Team", inverse_of: :direct_memberships
  belongs_to :user, class_name: "User", inverse_of: :team_memberships

  def self.generate_case_for_role_ranking(table_alias = self.table_name)
    mapping = self.roles
    size = mapping.size
    when_thens = mapping.keys.each_with_index.map do |role_name, idx|
      "WHEN #{ActiveRecord::Base.connection.quote(role_name.to_s)} THEN #{size - idx}"
    end

    "CASE #{table_alias}.role #{when_thens.join(' ')} ELSE 0 END"
  end
end