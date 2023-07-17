# frozen_string_literal: true

# This migration comes from doorkeeper_device_authorization_grant_engine (originally 20200629094624)
class CreateDoorkeeperDeviceGrants < ActiveRecord::Migration[6.0]
  def change
    create_table :oauth_device_grants do |t|
      t.references :resource_owner, null: true, type: :uuid
      t.references :application, null: false, type: :uuid, foreign_key: { to_table: :oauth_client_applications }
      t.string :device_code, null: false, index: { unique: true }
      t.string :user_code, null: true, index: { unique: true }
      t.integer :expires_in, null: false
      t.datetime :created_at, null: false
      t.datetime :last_polling_at, null: true
      t.string :scopes, null: false, default: ''
    end

    # Patch in permissible policy support.
    add_reference :oauth_device_grants, :permissible_policy,
                  null: true, type: :uuid, foreign_key: { to_table: :oauth_permissible_policies }
  end
end
