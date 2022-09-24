# frozen_string_literal: true

class CreateDoorkeeperTables < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_client_applications, id: :uuid do |t|
      t.string  :name, null: false

      t.uuid   :owner_id,   null: true
      t.string :owner_type, null: true

      t.string  :uid,          index: { unique: true }, null: false
      t.string  :secret,       null: false
      t.string  :pairwise_key, null: true

      t.text    :redirect_uri
      t.string  :scopes,        null: false, default: ''
      t.string  :grant_flows,   array: true, default: []
      t.boolean :confidential,  null: false, default: true

      # Is this application restricted to certain users or available to everyone?
      t.boolean :private, null: false, default: false

      t.string :icon_url
      t.boolean :verified, default: false

      t.timestamps null: false

      t.index [:owner_id, :owner_type], unique: false
    end

    create_table :oauth_access_grants, id: :uuid do |t|
      t.references :resource_owner,
                   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :application,
                   null: false, foreign_key: { to_table: :oauth_client_applications }, type: :uuid

      t.string   :token, index: { unique: true }, null: false

      t.integer  :expires_in, null: false
      t.text     :redirect_uri, null: false

      t.datetime :created_at, null: false
      t.datetime :revoked_at
      t.string   :scopes, null: false, default: ''

      t.uuid :permissible_id
    end

    create_table :oauth_access_tokens, id: :uuid do |t|
      t.references :resource_owner,
                   foreign_key: { to_table: :users }, index: true, type: :uuid
      t.references :application,
                   foreign_key: { to_table: :oauth_client_applications }, null: false, type: :uuid

      # If you use a custom token generator you may need to change this column
      # from string to text, so that it accepts tokens larger than 255
      # characters. More info on custom token generators in:
      # https://github.com/doorkeeper-gem/doorkeeper/tree/v3.0.0.rc1#custom-access-token-generator
      #
      # t.text :token, null: false
      t.string :token, index: { unique: true }, null: false

      t.string   :refresh_token, index: { unique: true }
      t.integer  :expires_in
      t.datetime :revoked_at
      t.datetime :created_at, null: false
      t.string   :scopes
      t.uuid     :permissible_id


      # The authorization server MAY issue a new refresh token, in which case
      # *the client MUST discard the old refresh token* and replace it with the
      # new refresh token. The authorization server MAY revoke the old
      # refresh token after issuing a new refresh token to the client.
      # @see https://datatracker.ietf.org/doc/html/rfc6749#section-6
      #
      # Doorkeeper implementation: if there is a `previous_refresh_token` column,
      # refresh tokens will be revoked after a related access token is used.
      # If there is no `previous_refresh_token` column, previous tokens are
      # revoked as soon as a new access token is created.
      #
      # Comment out this line if you want refresh tokens to be instantly
      # revoked after use.
      t.string   :previous_refresh_token, null: false, default: ""
    end

    create_table :oauth_openid_requests do |t|
      t.references :access_grant, null: false, index: true, on_delete: :cascade
      t.string :nonce, null: false
    end
  end
end
