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

ActiveRecord::Schema[8.0].define(version: 2026_01_27_190059) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_item_documents", force: :cascade do |t|
    t.bigint "action_item_id", null: false
    t.bigint "document_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_item_id", "document_id"], name: "index_action_item_documents_on_action_item_id_and_document_id", unique: true
    t.index ["action_item_id"], name: "index_action_item_documents_on_action_item_id"
    t.index ["document_id"], name: "index_action_item_documents_on_document_id"
  end

  create_table "action_items", force: :cascade do |t|
    t.bigint "dossier_id"
    t.text "description"
    t.date "due_date"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recurrence"
    t.string "context"
    t.bigint "waiting_for_party_id"
    t.string "waiting_for_description"
    t.boolean "someday", default: false, null: false
    t.integer "estimated_minutes"
    t.integer "position"
    t.boolean "next_action", default: false, null: false
    t.text "completion_notes"
    t.bigint "parent_id"
    t.text "notes"
    t.bigint "meeting_id"
    t.index ["dossier_id"], name: "index_action_items_on_dossier_id"
    t.index ["meeting_id"], name: "index_action_items_on_meeting_id"
    t.index ["parent_id"], name: "index_action_items_on_parent_id"
    t.index ["waiting_for_party_id"], name: "index_action_items_on_waiting_for_party_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "checklist_items", force: :cascade do |t|
    t.bigint "checklist_id", null: false
    t.text "description"
    t.integer "position"
    t.string "context"
    t.integer "estimated_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_id"], name: "index_checklist_items_on_checklist_id"
  end

  create_table "checklists", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "documents", force: :cascade do |t|
    t.string "name"
    t.bigint "dossier_id"
    t.bigint "folder_id"
    t.text "content_text"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "source_description"
    t.text "remarks"
    t.date "expires_at"
    t.text "expiration_description"
    t.index ["dossier_id"], name: "index_documents_on_dossier_id"
    t.index ["folder_id"], name: "index_documents_on_folder_id"
  end

  create_table "dossier_templates", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.jsonb "folders_data"
    t.jsonb "action_items_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dossiers", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "someday", default: false, null: false
    t.datetime "archived_at"
    t.boolean "work_dossier", default: false, null: false
    t.index ["archived_at"], name: "index_dossiers_on_archived_at"
  end

  create_table "expiring_items", force: :cascade do |t|
    t.string "name"
    t.date "expires_at"
    t.text "description"
    t.integer "notify_days_before"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "folders", force: :cascade do |t|
    t.string "name"
    t.bigint "dossier_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dossier_id"], name: "index_folders_on_dossier_id"
  end

  create_table "github_accounts", force: :cascade do |t|
    t.string "username", null: false
    t.text "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_github_accounts_on_username", unique: true
  end

  create_table "google_accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_google_accounts_on_email", unique: true
  end

  create_table "google_calendars", force: :cascade do |t|
    t.bigint "google_account_id", null: false
    t.string "calendar_id", null: false
    t.string "name"
    t.string "color"
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_account_id", "calendar_id"], name: "index_google_calendars_on_google_account_id_and_calendar_id", unique: true
    t.index ["google_account_id"], name: "index_google_calendars_on_google_account_id"
  end

  create_table "habit_completions", force: :cascade do |t|
    t.bigint "habit_id", null: false
    t.date "completed_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "count", default: 1, null: false
    t.index ["completed_on"], name: "index_habit_completions_on_completed_on"
    t.index ["habit_id", "completed_on"], name: "index_habit_completions_on_habit_id_and_completed_on", unique: true
    t.index ["habit_id"], name: "index_habit_completions_on_habit_id"
  end

  create_table "habits", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "frequency", default: "daily", null: false
    t.string "target_days"
    t.string "color", default: "blue"
    t.boolean "active", default: true, null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration_seconds"
    t.integer "target_count", default: 1
    t.index ["active"], name: "index_habits_on_active"
    t.index ["position"], name: "index_habits_on_position"
  end

  create_table "inbox_rules", force: :cascade do |t|
    t.string "term"
    t.bigint "dossier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dossier_id"], name: "index_inbox_rules_on_dossier_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "google_account_id", null: false
    t.string "google_event_id", null: false
    t.string "title"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text "notes"
    t.string "html_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_account_id", "google_event_id"], name: "index_meetings_on_google_account_id_and_google_event_id", unique: true
    t.index ["google_account_id"], name: "index_meetings_on_google_account_id"
    t.index ["start_time"], name: "index_meetings_on_start_time"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.bigint "dossier_id"
    t.bigint "folder_id"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dossier_id"], name: "index_notes_on_dossier_id"
    t.index ["folder_id"], name: "index_notes_on_folder_id"
  end

  create_table "parties", force: :cascade do |t|
    t.string "name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_parties_on_lower_name", unique: true
  end

  create_table "party_links", force: :cascade do |t|
    t.bigint "party_id", null: false
    t.string "linkable_type", null: false
    t.bigint "linkable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linkable_type", "linkable_id"], name: "index_party_links_on_linkable"
    t.index ["party_id"], name: "index_party_links_on_party_id"
  end

  create_table "review_steps", force: :cascade do |t|
    t.bigint "review_id", null: false
    t.bigint "review_template_step_id"
    t.string "title", null: false
    t.text "description"
    t.integer "position", null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id", "position"], name: "index_review_steps_on_review_id_and_position"
    t.index ["review_id", "status"], name: "index_review_steps_on_review_id_and_status"
    t.index ["review_id"], name: "index_review_steps_on_review_id"
    t.index ["review_template_step_id"], name: "index_review_steps_on_review_template_step_id"
  end

  create_table "review_template_steps", force: :cascade do |t|
    t.bigint "review_template_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_template_id", "position"], name: "index_review_template_steps_on_review_template_id_and_position"
    t.index ["review_template_id"], name: "index_review_template_steps_on_review_template_id"
  end

  create_table "review_templates", force: :cascade do |t|
    t.string "review_type", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_type", "active"], name: "index_review_templates_on_review_type_and_active"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "review_type", null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.string "period_key", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "paused_at"
    t.integer "current_step_position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_reviews_on_completed_at"
    t.index ["period_start"], name: "index_reviews_on_period_start"
    t.index ["review_type", "period_key"], name: "index_reviews_on_review_type_and_period_key", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.string "taggable_type", null: false
    t.bigint "taggable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_id_and_taggable_type_and_taggable_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#6366f1"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "task_contexts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_task_contexts_on_name", unique: true
    t.index ["position"], name: "index_task_contexts_on_position"
  end

  add_foreign_key "action_item_documents", "action_items"
  add_foreign_key "action_item_documents", "documents"
  add_foreign_key "action_items", "action_items", column: "parent_id"
  add_foreign_key "action_items", "dossiers"
  add_foreign_key "action_items", "meetings"
  add_foreign_key "action_items", "parties", column: "waiting_for_party_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "checklist_items", "checklists"
  add_foreign_key "documents", "dossiers"
  add_foreign_key "documents", "folders"
  add_foreign_key "folders", "dossiers"
  add_foreign_key "google_calendars", "google_accounts"
  add_foreign_key "habit_completions", "habits"
  add_foreign_key "inbox_rules", "dossiers"
  add_foreign_key "meetings", "google_accounts"
  add_foreign_key "notes", "dossiers"
  add_foreign_key "notes", "folders"
  add_foreign_key "party_links", "parties"
  add_foreign_key "review_steps", "review_template_steps", on_delete: :nullify
  add_foreign_key "review_steps", "reviews"
  add_foreign_key "review_template_steps", "review_templates"
  add_foreign_key "taggings", "tags"
end
