class CreateJwtSigningKeys < ActiveRecord::Migration[7.0]
  def change
    create_table :jwt_signing_keys, id: :uuid do |t|
      t.string :name, index: { unique: true }
      t.string :type, null: false

      t.boolean :enabled, default: true, null: false

      t.string :public_key, null: true, limit: 65_535
      t.string :private_key, null: false, limit: 65_535

      t.jsonb :key_params, null: true, default: {}

      t.timestamps
    end
  end
end
