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

ActiveRecord::Schema[8.1].define(version: 2026_08_01_183155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.string "announcement_type", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "round_id"
    t.datetime "scheduled_at"
    t.bigint "season_id", null: false
    t.datetime "sent_at"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_announcements_on_created_by_id"
    t.index ["round_id"], name: "index_announcements_on_round_id"
    t.index ["season_id"], name: "index_announcements_on_season_id"
  end

  create_table "challenge_results", force: :cascade do |t|
    t.bigint "challenge_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_immune", default: false, null: false
    t.text "note"
    t.integer "score"
    t.bigint "season_membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id", "season_membership_id"], name: "index_challenge_results_on_challenge_and_membership", unique: true
    t.index ["challenge_id"], name: "index_challenge_results_on_challenge_id"
    t.index ["season_membership_id"], name: "index_challenge_results_on_season_membership_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "result_mode", null: false
    t.bigint "round_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id"], name: "index_challenges_on_round_id", unique: true
  end

  create_table "idol_plays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "idol_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "voting_session_id", null: false
    t.index ["idol_id"], name: "index_idol_plays_on_idol_id"
    t.index ["voting_session_id"], name: "index_idol_plays_on_voting_session_id"
  end

  create_table "idols", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "granted_at", null: false
    t.bigint "granted_by_id", null: false
    t.bigint "holder_membership_id", null: false
    t.bigint "season_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["granted_by_id"], name: "index_idols_on_granted_by_id"
    t.index ["holder_membership_id"], name: "index_idols_on_holder_membership_id"
    t.index ["season_id"], name: "index_idols_on_season_id"
  end

  create_table "jury_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "finalist_membership_id", null: false
    t.bigint "juror_membership_id", null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["finalist_membership_id"], name: "index_jury_votes_on_finalist_membership_id"
    t.index ["juror_membership_id"], name: "index_jury_votes_on_juror_membership_id"
    t.index ["season_id", "juror_membership_id"], name: "index_jury_votes_on_season_and_juror", unique: true
    t.index ["season_id"], name: "index_jury_votes_on_season_id"
  end

  create_table "message_threads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_membership_id"
    t.string "kind", null: false
    t.string "name"
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_membership_id"], name: "index_message_threads_on_created_by_membership_id"
    t.index ["season_id"], name: "index_message_threads_on_season_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "message_thread_id", null: false
    t.bigint "sender_membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_thread_id"], name: "index_messages_on_message_thread_id"
    t.index ["sender_membership_id"], name: "index_messages_on_sender_membership_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.boolean "auto_closed", default: false, null: false
    t.datetime "challenge_deadline_at"
    t.datetime "challenge_reminder_sent_at"
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.string "phase", null: false
    t.bigint "season_id", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.datetime "vote_deadline_at"
    t.datetime "vote_reminder_sent_at"
    t.index ["season_id", "number"], name: "index_rounds_on_season_id_and_number", unique: true
    t.index ["season_id"], name: "index_rounds_on_season_id"
  end

  create_table "season_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_message_digest_sent_at"
    t.integer "placement"
    t.string "role", null: false
    t.bigint "season_id", null: false
    t.string "status", default: "active", null: false
    t.bigint "tribe_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["season_id", "user_id"], name: "index_season_memberships_on_season_id_and_user_id", unique: true
    t.index ["season_id"], name: "index_season_memberships_on_season_id"
    t.index ["tribe_id"], name: "index_season_memberships_on_tribe_id"
    t.index ["user_id"], name: "index_season_memberships_on_user_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "host_id", null: false
    t.string "invite_code", null: false
    t.integer "jury_size", default: 9, null: false
    t.string "name", null: false
    t.string "status", default: "setup", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_seasons_on_host_id"
    t.index ["invite_code"], name: "index_seasons_on_invite_code", unique: true
  end

  create_table "thread_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.bigint "message_thread_id", null: false
    t.bigint "season_membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_thread_id", "season_membership_id"], name: "index_thread_participants_on_thread_and_membership", unique: true
    t.index ["message_thread_id"], name: "index_thread_participants_on_message_thread_id"
    t.index ["season_membership_id"], name: "index_thread_participants_on_season_membership_id"
  end

  create_table "tribal_council_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "eliminated_membership_id"
    t.datetime "revealed_at", null: false
    t.jsonb "tally", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "voting_session_id", null: false
    t.index ["eliminated_membership_id"], name: "index_tribal_council_results_on_eliminated_membership_id"
    t.index ["voting_session_id"], name: "index_tribal_council_results_on_voting_session_id", unique: true
  end

  create_table "tribes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id"], name: "index_tribes_on_season_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.string "pin_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "voted_for_membership_id", null: false
    t.bigint "voter_membership_id", null: false
    t.bigint "voting_session_id", null: false
    t.index ["voted_for_membership_id"], name: "index_votes_on_voted_for_membership_id"
    t.index ["voter_membership_id"], name: "index_votes_on_voter_membership_id"
    t.index ["voting_session_id", "voter_membership_id"], name: "index_votes_on_session_and_voter", unique: true
    t.index ["voting_session_id"], name: "index_votes_on_voting_session_id"
  end

  create_table "voting_sessions", force: :cascade do |t|
    t.jsonb "candidate_ids", default: [], null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.jsonb "eligible_voter_ids", default: [], null: false
    t.datetime "opened_at"
    t.bigint "round_id", null: false
    t.integer "session_number", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id", "session_number"], name: "index_voting_sessions_on_round_id_and_session_number", unique: true
    t.index ["round_id"], name: "index_voting_sessions_on_round_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "rounds"
  add_foreign_key "announcements", "seasons"
  add_foreign_key "announcements", "users", column: "created_by_id"
  add_foreign_key "challenge_results", "challenges"
  add_foreign_key "challenge_results", "season_memberships"
  add_foreign_key "challenges", "rounds"
  add_foreign_key "idol_plays", "idols"
  add_foreign_key "idol_plays", "voting_sessions"
  add_foreign_key "idols", "season_memberships", column: "holder_membership_id"
  add_foreign_key "idols", "seasons"
  add_foreign_key "idols", "users", column: "granted_by_id"
  add_foreign_key "jury_votes", "season_memberships", column: "finalist_membership_id"
  add_foreign_key "jury_votes", "season_memberships", column: "juror_membership_id"
  add_foreign_key "jury_votes", "seasons"
  add_foreign_key "message_threads", "season_memberships", column: "created_by_membership_id"
  add_foreign_key "message_threads", "seasons"
  add_foreign_key "messages", "message_threads"
  add_foreign_key "messages", "season_memberships", column: "sender_membership_id"
  add_foreign_key "rounds", "seasons"
  add_foreign_key "season_memberships", "seasons"
  add_foreign_key "season_memberships", "tribes"
  add_foreign_key "season_memberships", "users"
  add_foreign_key "seasons", "users", column: "host_id"
  add_foreign_key "thread_participants", "message_threads"
  add_foreign_key "thread_participants", "season_memberships"
  add_foreign_key "tribal_council_results", "season_memberships", column: "eliminated_membership_id"
  add_foreign_key "tribal_council_results", "voting_sessions"
  add_foreign_key "tribes", "seasons"
  add_foreign_key "votes", "season_memberships", column: "voted_for_membership_id"
  add_foreign_key "votes", "season_memberships", column: "voter_membership_id"
  add_foreign_key "votes", "voting_sessions"
  add_foreign_key "voting_sessions", "rounds"
end
