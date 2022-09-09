class CreateOauthPermissibles < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_permissibles, id: :uuid do |t|
      t.uuid :policy_id, null: false, index: { unique: false }

      t.boolean :deny, default: false

      # More magic!
      t.uuid :resource_id, null: false
      t.string :resource_type, null: false

      t.datetime :created_at, null: false
      
      t.index [:resource_type, :resource_id]
    end
  end
end
