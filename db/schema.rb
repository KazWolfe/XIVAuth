# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_27_034414) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "ffxiv_character_refresh_error", ["UNSPECIFIED", "HIDDEN_CHARACTER", "PROFILE_PRIVATE", "NOT_FOUND"]
  create_enum "team_roles", ["admin", "developer", "member"]
  create_enum "user_roles", ["developer", "admin"]

  create_table "character_bans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "character_type"
    t.uuid "character_id"
    t.string "reason"
    t.datetime "created_at", null: false
    t.index ["character_type", "character_id"], name: "index_character_bans_on_character"
  end

  create_table "character_registrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "character_id"
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "extra_data", default: {}, null: false
    t.string "source", default: "internal", null: false
    t.string "verification_type"
    t.index ["character_id"], name: "index_character_registrations_on_character_id"
    t.index ["user_id"], name: "index_character_registrations_on_user_id"
  end

  create_table "client_application_oauth_clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.string "name", null: false
    t.boolean "enabled", default: true, null: false
    t.string "client_id", null: false
    t.string "client_secret"
    t.string "grant_flows", default: [], array: true
    t.string "redirect_uris", default: [], array: true
    t.string "scopes"
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.index ["application_id"], name: "index_client_application_oauth_clients_on_application_id"
    t.index ["client_id"], name: "index_client_application_oauth_clients_on_client_id", unique: true
  end

  create_table "client_application_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.string "icon_url"
    t.string "homepage_url"
    t.string "privacy_policy_url"
    t.string "terms_of_service_url"
    t.index ["application_id"], name: "index_client_application_profiles_on_application_id"
  end

  create_table "client_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "owner_type"
    t.uuid "owner_id"
    t.boolean "private", default: false, null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_client_applications_on_owner"
  end

  create_table "ffxiv_characters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "lodestone_id", null: false
    t.string "content_id"
    t.string "name", null: false
    t.string "home_world", null: false
    t.string "data_center", null: false
    t.string "avatar_url", null: false
    t.string "portrait_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "refresh_fail_reason", enum_type: "ffxiv_character_refresh_error"
    t.index ["content_id"], name: "index_ffxiv_characters_on_content_id", unique: true, where: "((content_id IS NOT NULL) OR ((content_id)::text <> ''::text))"
    t.index ["lodestone_id"], name: "index_ffxiv_characters_on_lodestone_id", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "jwt_signing_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "type", null: false
    t.boolean "enabled", default: true, null: false
    t.string "public_key", limit: 65535
    t.string "private_key", limit: 65535, null: false
    t.jsonb "key_params", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.index ["name"], name: "index_jwt_signing_keys_on_name", unique: true
  end

  create_table "oauth_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "resource_owner_type", null: false
    t.uuid "resource_owner_id", null: false
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.uuid "permissible_policy_id"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["permissible_policy_id"], name: "index_oauth_access_grants_on_permissible_policy_id"
    t.index ["resource_owner_type", "resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "resource_owner_type"
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.uuid "permissible_policy_id"
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["permissible_policy_id"], name: "index_oauth_access_tokens_on_permissible_policy_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, where: "((refresh_token IS NOT NULL) OR ((refresh_token)::text <> ''::text))"
    t.index ["resource_owner_type", "resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_client_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.string "owner_type"
    t.uuid "owner_id"
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_oauth_client_applications_on_owner"
    t.index ["uid"], name: "index_oauth_client_applications_on_uid", unique: true
  end

  create_table "oauth_device_grants", force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "device_code", null: false
    t.string "user_code"
    t.integer "expires_in", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_polling_at", precision: nil
    t.string "scopes", default: "", null: false
    t.uuid "permissible_policy_id"
    t.index ["application_id"], name: "index_oauth_device_grants_on_application_id"
    t.index ["device_code"], name: "index_oauth_device_grants_on_device_code", unique: true
    t.index ["permissible_policy_id"], name: "index_oauth_device_grants_on_permissible_policy_id"
    t.index ["resource_owner_id"], name: "index_oauth_device_grants_on_resource_owner_id"
    t.index ["user_code"], name: "index_oauth_device_grants_on_user_code", unique: true
  end

  create_table "oauth_permissible_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
  end

  create_table "oauth_permissible_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "policy_id"
    t.boolean "deny", default: false
    t.string "resource_type"
    t.string "resource_id"
    t.datetime "created_at", null: false
    t.index ["policy_id"], name: "index_oauth_permissible_rules_on_policy_id"
    t.index ["resource_type", "resource_id"], name: "index_oauth_permissible_rules_on_resource"
  end

  create_table "site_announcements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "type"
    t.text "title"
    t.text "body"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "team_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.enum "role", default: "member", null: false, enum_type: "team_roles"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "team_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.string "avatar_url"
    t.string "website_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_profiles_on_team_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "parent_id"
    t.boolean "inherit_parent_memberships", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["parent_id"], name: "index_teams_on_parent_id"
  end

  create_table "user_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "display_name", limit: 64, null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "user_social_identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "email"
    t.string "name"
    t.string "nickname"
    t.json "raw_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_used_at"
    t.string "access_token"
    t.string "refresh_token"
    t.index ["provider", "external_id"], name: "index_user_social_identities_on_provider_and_external_id", unique: true
    t.index ["user_id"], name: "index_user_social_identities_on_user_id"
  end

  create_table "user_totp_credentials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "otp_secret", null: false
    t.decimal "consumed_timestep"
    t.boolean "otp_enabled", default: false
    t.string "otp_backup_codes", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_totp_credentials_on_user_id", unique: true
  end

  create_table "user_webauthn_credentials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "external_id", null: false
    t.string "public_key", null: false
    t.string "nickname", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_used_at"
    t.index ["external_id"], name: "index_user_webauthn_credentials_on_external_id", unique: true
    t.index ["user_id", "nickname"], name: "index_user_webauthn_credentials_on_user_id_and_nickname", unique: true
    t.index ["user_id"], name: "index_user_webauthn_credentials_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "roles", default: [], null: false, array: true, enum_type: "user_roles"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "character_registrations", "ffxiv_characters", column: "character_id"
  add_foreign_key "client_application_oauth_clients", "client_applications", column: "application_id"
  add_foreign_key "client_application_profiles", "client_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "client_application_oauth_clients", column: "application_id"
  add_foreign_key "oauth_access_grants", "oauth_permissible_policies", column: "permissible_policy_id"
  add_foreign_key "oauth_access_tokens", "client_application_oauth_clients", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_permissible_policies", column: "permissible_policy_id"
  add_foreign_key "oauth_device_grants", "client_application_oauth_clients", column: "application_id"
  add_foreign_key "oauth_device_grants", "oauth_permissible_policies", column: "permissible_policy_id"
  add_foreign_key "oauth_permissible_rules", "oauth_permissible_policies", column: "policy_id"
  add_foreign_key "team_memberships", "teams", on_delete: :cascade
  add_foreign_key "team_memberships", "users", on_delete: :cascade
  add_foreign_key "team_profiles", "teams", on_delete: :cascade
  add_foreign_key "teams", "teams", column: "parent_id", on_delete: :cascade
  add_foreign_key "user_profiles", "users"
  add_foreign_key "user_social_identities", "users"
  add_foreign_key "user_totp_credentials", "users"
  add_foreign_key "user_webauthn_credentials", "users"
end
