class CreateUsersProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :users_profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }

      t.string :display_name, null: false

      t.index "lower(display_name)", unique: true
    end

    reversible do |dir|
      dir.up do
        User.reset_column_information
        User.all.each do |u|
          # We don't want to leak any information about user IDs, so let's just make something up
          u.build_profile(display_name: "XIVAuthUser_#{Random.hex(6)}")
          u.profile.save(validate: false)
        end
      end
    end
  end
end
