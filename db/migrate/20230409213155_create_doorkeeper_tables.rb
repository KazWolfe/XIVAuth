# frozen_string_literal: true

class CreateDoorkeeperTables < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_client_applications, id: :uuid do |t|
      t.string  :name,    null: false
      t.string  :uid,     null: false, index: { unique: true }
      t.string  :secret,  null: false

      # Application owner
      t.references :owner, type: :uuid, polymorphic: true, null: true, index: true

      # Remove `null: false` if you are planning to use grant flows
      # that doesn't require redirect URI to be used during authorization
      # like Client Credentials flow or Resource Owner Password.
      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ''
      t.boolean :confidential, null: false, default: true
      t.timestamps             null: false
    end

    create_table :oauth_access_grants, id: :uuid do |t|
      t.references :resource_owner,  type: :uuid, null: false, polymorphic: true
      t.references :application,     type: :uuid, null: false, foreign_key: { to_table: :oauth_client_applications }
      t.string   :token,             null: false, index: { unique: true }
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.string   :scopes,            null: false, default: ''
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
    end

    create_table :oauth_access_tokens, id: :uuid do |t|
      t.references :resource_owner, type: :uuid, index: true, polymorphic: true

      # Remove `null: false` if you are planning to use Password
      # Credentials Grant flow that doesn't require an application.
      t.references :application,type: :uuid, null: false, foreign_key: { to_table: :oauth_client_applications }

      # If you use a custom token generator you may need to change this column
      # from string to text, so that it accepts tokens larger than 255
      # characters. More info on custom token generators in:
      # https://github.com/doorkeeper-gem/doorkeeper/tree/v3.0.0.rc1#custom-access-token-generator
      #
      # t.text :token, null: false
      t.string :token, null: false, index: { unique: true }

      t.string   :refresh_token, index: { unique: true, where: "(refresh_token IS NOT NULL) OR (refresh_token != '')" }
      t.integer  :expires_in
      t.string   :scopes
      t.datetime :created_at, null: false
      t.datetime :revoked_at

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
  end
end
