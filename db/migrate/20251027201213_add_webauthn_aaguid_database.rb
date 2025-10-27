class AddWebauthnAaguidDatabase < ActiveRecord::Migration[8.1]
  def change
    create_table :webauthn_device_classes, id: :uuid do |t|
      t.string :name, null: false
      t.text :icon_dark, null: true
      t.text :icon_light, null: true

      t.datetime :updated_at, null: false
    end
  end
end
