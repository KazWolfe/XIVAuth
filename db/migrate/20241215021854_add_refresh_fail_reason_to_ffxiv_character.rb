class AddRefreshFailReasonToFFXIVCharacter < ActiveRecord::Migration[8.0]
  def up
    create_enum :ffxiv_character_refresh_error, %w[UNSPECIFIED HIDDEN_CHARACTER PROFILE_PRIVATE NOT_FOUND]
    add_column :ffxiv_characters, :refresh_fail_reason, :enum, enum_type: "ffxiv_character_refresh_error", null: true
  end

  def down
    remove_column :ffxiv_characters, :refresh_fail_reason
  end
end
