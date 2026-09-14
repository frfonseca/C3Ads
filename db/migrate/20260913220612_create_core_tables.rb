class CreateCoreTables < ActiveRecord::Migration[8.1]
  def up
    create_table :accounts do |t|
      t.string  :name, null: false
      t.string  :ig_user_id
      t.string  :ig_username
      t.string  :facebook_page_id
      t.string  :business_id
      t.string  :ad_account_id
      t.text    :access_token
      t.datetime :token_expires_at
      t.timestamps
    end
    add_index :accounts, :ig_user_id, unique: true, where: "ig_user_id IS NOT NULL"

    create_table :projects do |t|
      t.references :account, foreign_key: true
      t.string  :name, null: false
      t.string  :kind, null: false, default: "generic"  # property | local_business | generic
      t.text    :description
      t.string  :whatsapp_number
      t.string  :llm_provider
      t.string  :llm_model
      t.string  :llm_fallbacks, array: true, default: []
      t.decimal :monthly_cost_limit_usd, precision: 10, scale: 2
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :brands do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :primary_color,    default: "#1a1a1a"
      t.string :secondary_color,  default: "#4a4a4a"
      t.string :accent_color,     default: "#0066cc"
      t.string :text_color,       default: "#1a1a1a"
      t.string :background_color, default: "#ffffff"
      t.string :heading_font, default: "Inter"
      t.string :body_font,    default: "Inter"
      t.text   :tone_of_voice
      t.string :do_say,    array: true, default: []
      t.string :dont_say,  array: true, default: []
      t.string :default_hashtags, array: true, default: []
      t.text   :signature
      t.boolean :watermark_posts, null: false, default: false
      t.timestamps
    end

    create_table :assets do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :kind, null: false, default: "photo"       # logo | photo | video | document
      t.string  :visibility, null: false, default: "private" # private | internal | public
      t.string  :title
      t.text    :notes
      t.string  :tags, array: true, default: []
      t.jsonb   :vision_analysis
      t.integer :usage_count, null: false, default: 0
      t.datetime :last_used_at
      t.datetime :expires_at
      t.timestamps
    end
    add_index :assets, [ :project_id, :kind ]
    add_index :assets, :visibility
    add_index :assets, :tags, using: :gin

    create_table :asset_collections do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text   :description
      t.timestamps
    end

    create_table :asset_collection_memberships do |t|
      t.references :asset, null: false, foreign_key: true
      t.references :asset_collection, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :asset_collection_memberships, [ :asset_collection_id, :asset_id ],
              unique: true, name: "idx_collection_membership_unique"

    create_table :posts do |t|
      t.references :project, null: false, foreign_key: true
      t.references :account, foreign_key: true
      t.string  :state, null: false, default: "draft"
      t.string  :media_type, null: false, default: "carousel" # image | carousel | reel | story
      t.text    :caption
      t.string  :hashtags, array: true, default: []
      t.jsonb   :generation_meta
      t.integer :regeneration_count, null: false, default: 0

      t.datetime :approved_at
      t.string   :approved_by
      t.datetime :scheduled_for
      t.datetime :published_at

      t.string  :ig_media_id
      t.string  :ig_container_id
      t.string  :ig_permalink
      t.text    :failure_reason

      t.timestamps
    end
    add_index :posts, [ :project_id, :state ]
    add_index :posts, :scheduled_for
    add_index :posts, :ig_media_id, unique: true, where: "ig_media_id IS NOT NULL"

    create_table :post_media do |t|
      t.references :post,  null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.text    :alt_text
      t.string  :ig_child_container_id
      t.timestamps
    end
    add_index :post_media, [ :post_id, :position ], unique: true
  end

  def down
    drop_table :post_media
    drop_table :posts
    drop_table :asset_collection_memberships
    drop_table :asset_collections
    drop_table :assets
    drop_table :brands
    drop_table :projects
    drop_table :accounts
  end
end
