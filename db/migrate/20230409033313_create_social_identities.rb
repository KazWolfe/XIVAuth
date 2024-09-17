class CreateSocialIdentities < ActiveRecord::Migration[7.0]
  def change
    create_table :users_social_identities, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: { to_table: :users }

      t.string :provider, null: false
      t.string :external_id, null: false # uid

      # Optional strings returned from OmniAuth, normalized to their style.
      t.string :email
      t.string :name
      t.string :nickname

      # Raw metadata from the OAuth provider, used for sanity mostly
      t.json :raw_info

      t.timestamps
      t.datetime :last_used_at, null: true

      t.index %i[provider external_id], unique: true
    end
  end
end
