class CreateSocialIdentities < ActiveRecord::Migration[7.0]
  def change
    create_table :social_identities do |t|
      t.references :user, type: :uuid, null: true

      t.string :provider, null: false
      t.string :external_id, null: false  # uid

      # Optional strings returned from OmniAuth, normalized to their style.
      t.string :email
      t.string :name
      t.string :nickname

      # Raw metadata from the OAuth provider, used for sanity mostly
      t.json :raw_info

      t.timestamps

      t.index %i[provider external_id], unique: true
    end
  end
end
