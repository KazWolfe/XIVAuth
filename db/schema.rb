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

ActiveRecord::Schema[7.0].define(version: 2023_04_09_033313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "character_registrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "character_id"
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_registrations_on_character_id"
    t.index ["user_id"], name: "index_character_registrations_on_user_id"
  end

  create_table "ffxiv_characters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "lodestone_id", null: false
    t.string "content_id"
    t.string "name", null: false
    t.string "home_world", null: false
    t.string "data_center", null: false
    t.string "avatar_url", null: false
    t.string "portrait_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_ffxiv_characters_on_content_id", unique: true, where: "((content_id IS NOT NULL) OR ((content_id)::text <> ''::text))"
    t.index ["lodestone_id"], name: "index_ffxiv_characters_on_lodestone_id", unique: true
  end

  create_table "social_identities", force: :cascade do |t|
    t.uuid "user_id"
    t.string "provider", null: false
    t.string "external_id", null: false
    t.string "email"
    t.string "name"
    t.string "nickname"
    t.json "raw_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_id"], name: "index_social_identities_on_provider_and_external_id", unique: true
    t.index ["user_id"], name: "index_social_identities_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  add_foreign_key "character_registrations", "ffxiv_characters", column: "character_id"
end
