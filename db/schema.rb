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

ActiveRecord::Schema[7.0].define(version: 2022_10_09_013550) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "character_registrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "character_type"
    t.string "character_id"
    t.datetime "verified_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_character_registrations_on_user_id"
  end

  create_table "characters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "lodestone_id", null: false
    t.uuid "user_id", null: false
    t.bigint "content_id"
    t.string "character_name"
    t.string "home_datacenter"
    t.string "home_world"
    t.string "avatar_url"
    t.datetime "last_lodestone_update", precision: nil
    t.datetime "verified_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_characters_on_content_id"
    t.index ["lodestone_id", "user_id"], name: "index_characters_on_lodestone_id_and_user_id", unique: true
    t.index ["lodestone_id"], name: "index_characters_on_lodestone_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "oauth_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id", null: false
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.uuid "permissible_id"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.uuid "permissible_id"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_client_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "owner_id"
    t.string "owner_type"
    t.string "uid", null: false
    t.string "secret", null: false
    t.string "pairwise_key"
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.string "grant_flows", default: [], array: true
    t.boolean "confidential", default: true, null: false
    t.boolean "private", default: false, null: false
    t.string "icon_url"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_client_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_client_applications_on_uid", unique: true
  end

  create_table "oauth_device_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "device_code", null: false
    t.string "user_code"
    t.string "scopes", default: "", null: false
    t.uuid "permissible_id"
    t.boolean "denied"
    t.integer "expires_in", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_polling_at", precision: nil
    t.index ["application_id"], name: "index_oauth_device_grants_on_application_id"
    t.index ["device_code"], name: "index_oauth_device_grants_on_device_code", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_device_grants_on_resource_owner_id"
    t.index ["user_code"], name: "index_oauth_device_grants_on_user_code", unique: true
  end

  create_table "oauth_openid_requests", force: :cascade do |t|
    t.bigint "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "oauth_permissibles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "policy_id", null: false
    t.boolean "deny", default: false
    t.uuid "resource_id", null: false
    t.string "resource_type", null: false
    t.datetime "created_at", null: false
    t.index ["policy_id"], name: "index_oauth_permissibles_on_policy_id"
    t.index ["resource_type", "resource_id"], name: "index_oauth_permissibles_on_resource_type_and_resource_id"
  end

  create_table "team_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "username", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
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
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_external_identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "external_email"
    t.datetime "last_used_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_users_external_identities_on_external_id", unique: true
    t.index ["provider", "external_id"], name: "index_users_external_identities_on_provider_and_external_id", unique: true
    t.index ["provider"], name: "index_users_external_identities_on_provider"
    t.index ["user_id"], name: "index_users_external_identities_on_user_id"
  end

  create_table "users_totp_credentials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "otp_secret", null: false
    t.integer "consumed_timestep"
    t.string "otp_backup_codes", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_users_totp_credentials_on_user_id"
  end

  create_table "users_webauthn_credentials", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "external_id", null: false
    t.string "public_key", null: false
    t.string "nickname", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_users_webauthn_credentials_on_external_id", unique: true
    t.index ["nickname", "user_id"], name: "index_users_webauthn_credentials_on_nickname_and_user_id", unique: true
    t.index ["user_id"], name: "index_users_webauthn_credentials_on_user_id"
  end

  add_foreign_key "character_registrations", "users"
  add_foreign_key "characters", "users"
  add_foreign_key "oauth_access_grants", "oauth_client_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_client_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "oauth_device_grants", "oauth_client_applications", column: "application_id"
  add_foreign_key "oauth_device_grants", "users", column: "resource_owner_id"
  add_foreign_key "users_external_identities", "users"
  add_foreign_key "users_totp_credentials", "users"
  add_foreign_key "users_webauthn_credentials", "users"
end
