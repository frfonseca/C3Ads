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

ActiveRecord::Schema[8.1].define(version: 2026_09_14_010550) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.text "access_token"
    t.string "ad_account_id"
    t.string "business_id"
    t.datetime "created_at", null: false
    t.string "facebook_page_id"
    t.string "ig_user_id"
    t.string "ig_username"
    t.string "name", null: false
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.index ["ig_user_id"], name: "index_accounts_on_ig_user_id", unique: true, where: "(ig_user_id IS NOT NULL)"
  end

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

  create_table "asset_collection_memberships", force: :cascade do |t|
    t.bigint "asset_collection_id", null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["asset_collection_id", "asset_id"], name: "idx_collection_membership_unique", unique: true
    t.index ["asset_collection_id"], name: "index_asset_collection_memberships_on_asset_collection_id"
    t.index ["asset_id"], name: "index_asset_collection_memberships_on_asset_id"
  end

  create_table "asset_collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_asset_collections_on_project_id"
  end

  create_table "assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "kind", default: "photo", null: false
    t.datetime "last_used_at"
    t.text "notes"
    t.bigint "project_id", null: false
    t.string "tags", default: [], array: true
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0, null: false
    t.string "visibility", default: "private", null: false
    t.jsonb "vision_analysis"
    t.index ["project_id", "kind"], name: "index_assets_on_project_id_and_kind"
    t.index ["project_id"], name: "index_assets_on_project_id"
    t.index ["tags"], name: "index_assets_on_tags", using: :gin
    t.index ["visibility"], name: "index_assets_on_visibility"
  end

  create_table "brands", force: :cascade do |t|
    t.string "accent_color", default: "#0066cc"
    t.string "background_color", default: "#ffffff"
    t.string "body_font", default: "Inter"
    t.datetime "created_at", null: false
    t.string "default_hashtags", default: [], array: true
    t.string "do_say", default: [], array: true
    t.string "dont_say", default: [], array: true
    t.bigint "favicon_asset_id"
    t.string "heading_font", default: "Inter"
    t.bigint "logo_asset_id"
    t.bigint "logo_dark_asset_id"
    t.string "primary_color", default: "#1a1a1a"
    t.bigint "project_id", null: false
    t.string "secondary_color", default: "#4a4a4a"
    t.text "signature"
    t.string "text_color", default: "#1a1a1a"
    t.text "tone_of_voice"
    t.datetime "updated_at", null: false
    t.boolean "watermark_posts", default: false, null: false
    t.index ["favicon_asset_id"], name: "index_brands_on_favicon_asset_id"
    t.index ["logo_asset_id"], name: "index_brands_on_logo_asset_id"
    t.index ["logo_dark_asset_id"], name: "index_brands_on_logo_dark_asset_id"
    t.index ["project_id"], name: "index_brands_on_project_id", unique: true
  end

  create_table "destinations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", default: "whatsapp", null: false
    t.bigint "landing_page_id"
    t.bigint "post_id"
    t.text "prefilled_message"
    t.datetime "updated_at", null: false
    t.string "whatsapp_number"
    t.index ["landing_page_id"], name: "index_destinations_on_landing_page_id"
    t.index ["post_id"], name: "index_destinations_on_post_id"
  end

  create_table "generation_costs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.string "model"
    t.integer "output_tokens"
    t.bigint "post_id"
    t.bigint "project_id", null: false
    t.string "provider"
    t.datetime "updated_at", null: false
    t.decimal "usd", precision: 10, scale: 5, default: "0.0"
    t.index ["post_id"], name: "index_generation_costs_on_post_id"
    t.index ["project_id", "created_at"], name: "index_generation_costs_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_generation_costs_on_project_id"
  end

  create_table "landing_media", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.bigint "landing_page_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_landing_media_on_asset_id"
    t.index ["landing_page_id", "position"], name: "index_landing_media_on_landing_page_id_and_position", unique: true
    t.index ["landing_page_id"], name: "index_landing_media_on_landing_page_id"
  end

  create_table "landing_pages", force: :cascade do |t|
    t.jsonb "blocks"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "kind", default: "lead_capture", null: false
    t.bigint "post_id"
    t.string "previous_slugs", default: [], array: true
    t.bigint "project_id", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "state", default: "draft", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_landing_pages_on_post_id"
    t.index ["project_id"], name: "index_landing_pages_on_project_id"
    t.index ["slug"], name: "index_landing_pages_on_slug", unique: true
  end

  create_table "leads", force: :cascade do |t|
    t.datetime "anonymized_at"
    t.datetime "consent_at"
    t.text "consent_text"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "landing_page_id"
    t.text "message"
    t.string "name"
    t.string "phone"
    t.bigint "post_id"
    t.bigint "project_id", null: false
    t.bigint "short_link_id"
    t.string "source", default: "form", null: false
    t.string "status", default: "novo", null: false
    t.datetime "updated_at", null: false
    t.index ["landing_page_id"], name: "index_leads_on_landing_page_id"
    t.index ["post_id"], name: "index_leads_on_post_id"
    t.index ["project_id", "status"], name: "index_leads_on_project_id_and_status"
    t.index ["project_id"], name: "index_leads_on_project_id"
    t.index ["short_link_id"], name: "index_leads_on_short_link_id"
  end

  create_table "link_clicks", force: :cascade do |t|
    t.datetime "clicked_at", null: false
    t.datetime "created_at", null: false
    t.string "ip_hash"
    t.string "referrer"
    t.bigint "short_link_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["short_link_id"], name: "index_link_clicks_on_short_link_id"
  end

  create_table "page_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_hash"
    t.bigint "landing_page_id", null: false
    t.string "referrer"
    t.bigint "short_link_id"
    t.datetime "updated_at", null: false
    t.datetime "viewed_at", null: false
    t.index ["landing_page_id"], name: "index_page_views_on_landing_page_id"
    t.index ["short_link_id"], name: "index_page_views_on_short_link_id"
  end

  create_table "post_media", force: :cascade do |t|
    t.text "alt_text"
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.string "ig_child_container_id"
    t.integer "position", default: 0, null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_post_media_on_asset_id"
    t.index ["post_id", "position"], name: "index_post_media_on_post_id_and_position", unique: true
    t.index ["post_id"], name: "index_post_media_on_post_id"
  end

  create_table "post_metrics", force: :cascade do |t|
    t.datetime "collected_at", null: false
    t.integer "comments"
    t.datetime "created_at", null: false
    t.integer "impressions"
    t.integer "likes"
    t.bigint "post_id", null: false
    t.integer "reach"
    t.integer "saved"
    t.integer "shares"
    t.datetime "updated_at", null: false
    t.index ["post_id", "collected_at"], name: "index_post_metrics_on_post_id_and_collected_at", unique: true
    t.index ["post_id"], name: "index_post_metrics_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "approved_at"
    t.string "approved_by"
    t.text "caption"
    t.datetime "created_at", null: false
    t.text "failure_reason"
    t.jsonb "generation_meta"
    t.string "hashtags", default: [], array: true
    t.string "ig_container_id"
    t.string "ig_media_id"
    t.string "ig_permalink"
    t.string "media_type", default: "carousel", null: false
    t.bigint "project_id", null: false
    t.datetime "published_at"
    t.integer "regeneration_count", default: 0, null: false
    t.datetime "scheduled_for"
    t.string "state", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_posts_on_account_id"
    t.index ["ig_media_id"], name: "index_posts_on_ig_media_id", unique: true, where: "(ig_media_id IS NOT NULL)"
    t.index ["project_id", "state"], name: "index_posts_on_project_id_and_state"
    t.index ["project_id"], name: "index_posts_on_project_id"
    t.index ["scheduled_for"], name: "index_posts_on_scheduled_for"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "account_id"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", default: "generic", null: false
    t.string "llm_fallbacks", default: [], array: true
    t.string "llm_model"
    t.string "llm_provider"
    t.decimal "monthly_cost_limit_usd", precision: 10, scale: 2
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_number"
    t.index ["account_id"], name: "index_projects_on_account_id"
  end

  create_table "publish_attempts", force: :cascade do |t|
    t.string "container_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "outcome", null: false
    t.bigint "post_id", null: false
    t.text "request_summary"
    t.text "response_summary"
    t.string "step", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "step"], name: "index_publish_attempts_on_post_id_and_step"
    t.index ["post_id"], name: "index_publish_attempts_on_post_id"
  end

  create_table "short_links", force: :cascade do |t|
    t.integer "click_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "destination_id"
    t.bigint "post_id"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_short_links_on_destination_id"
    t.index ["post_id"], name: "index_short_links_on_post_id"
    t.index ["slug"], name: "index_short_links_on_slug", unique: true
  end

  create_table "system_alerts", force: :cascade do |t|
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.text "message", null: false
    t.datetime "notified_at"
    t.datetime "resolved_at"
    t.string "severity", default: "warning", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "resolved_at"], name: "index_system_alerts_on_kind_and_resolved_at"
  end

  create_table "video_renders", force: :cascade do |t|
    t.bigint "asset_id"
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.text "error_message"
    t.bigint "post_id", null: false
    t.jsonb "spec"
    t.string "state", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_video_renders_on_asset_id"
    t.index ["post_id"], name: "index_video_renders_on_post_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "asset_collection_memberships", "asset_collections"
  add_foreign_key "asset_collection_memberships", "assets"
  add_foreign_key "asset_collections", "projects"
  add_foreign_key "assets", "projects"
  add_foreign_key "brands", "assets", column: "favicon_asset_id"
  add_foreign_key "brands", "assets", column: "logo_asset_id"
  add_foreign_key "brands", "assets", column: "logo_dark_asset_id"
  add_foreign_key "brands", "projects"
  add_foreign_key "destinations", "landing_pages"
  add_foreign_key "destinations", "posts"
  add_foreign_key "generation_costs", "posts"
  add_foreign_key "generation_costs", "projects"
  add_foreign_key "landing_media", "assets"
  add_foreign_key "landing_media", "landing_pages"
  add_foreign_key "landing_pages", "posts"
  add_foreign_key "landing_pages", "projects"
  add_foreign_key "leads", "landing_pages"
  add_foreign_key "leads", "posts"
  add_foreign_key "leads", "projects"
  add_foreign_key "leads", "short_links"
  add_foreign_key "link_clicks", "short_links"
  add_foreign_key "page_views", "landing_pages"
  add_foreign_key "page_views", "short_links"
  add_foreign_key "post_media", "assets"
  add_foreign_key "post_media", "posts"
  add_foreign_key "post_metrics", "posts"
  add_foreign_key "posts", "accounts"
  add_foreign_key "posts", "projects"
  add_foreign_key "projects", "accounts"
  add_foreign_key "publish_attempts", "posts"
  add_foreign_key "short_links", "destinations"
  add_foreign_key "short_links", "posts"
  add_foreign_key "video_renders", "assets"
  add_foreign_key "video_renders", "posts"
end
