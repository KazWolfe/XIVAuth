class AccessControlList < ActiveRecord::Migration[8.0]
  def change
    create_table :client_application_access_control_lists, id: :uuid do |t|
      t.references :application, type: :uuid, index: true, null: false, foreign_key: { to_table: :client_applications }

      t.boolean :deny, null: false, default: false

      t.references :principal, type: :uuid, null: false, polymorphic: true
      t.boolean :include_team_descendants, null: false, default: false

      t.timestamps
    end
  end
end
