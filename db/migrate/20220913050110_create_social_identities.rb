class CreateSocialIdentities < ActiveRecord::Migration[7.0]
  def change
    create_table :social_identities, force: :cascade, id: :uuid do |t|
      t.references :user, null: true, foreign_key: true, type: :uuid

      t.string :provider, index: { unique: false }, null: false
      t.string :external_id, index: { unique: true }, null: false
      t.string :external_email, null: true
      
      t.timestamp :last_used_at, null: true

      t.timestamps

      t.index [:provider, :external_id], unique: true
    end
  end
end
