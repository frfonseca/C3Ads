class CreateLandingAndLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :landing_pages do |t|
      t.references :project, null: false, foreign_key: true
      # post_id opcional: preenchido = página daquela campanha; vazio = permanente.
      t.references :post, foreign_key: true
      t.string  :kind, null: false, default: "lead_capture"
      t.string  :slug, null: false
      t.string  :state, null: false, default: "draft"
      t.string  :title
      t.jsonb   :blocks
      t.string  :previous_slugs, array: true, default: []
      t.datetime :expires_at
      t.datetime :published_at
      t.timestamps
    end
    add_index :landing_pages, :slug, unique: true

    create_table :landing_media do |t|
      t.references :landing_page, null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :landing_media, [ :landing_page_id, :position ], unique: true

    create_table :destinations do |t|
      t.references :post, foreign_key: true
      t.string :kind, null: false, default: "whatsapp"  # whatsapp | landing | profile
      t.string :whatsapp_number
      t.text   :prefilled_message
      t.references :landing_page, foreign_key: true
      t.timestamps
    end

    create_table :short_links do |t|
      t.references :post, foreign_key: true
      t.references :destination, foreign_key: true
      t.string  :slug, null: false
      t.integer :click_count, null: false, default: 0
      t.timestamps
    end
    add_index :short_links, :slug, unique: true

    create_table :link_clicks do |t|
      t.references :short_link, null: false, foreign_key: true
      t.string   :referrer
      t.string   :user_agent
      # Nunca IP em claro: só hash com salt, o que mantém a tabela fora do
      # escopo de dado pessoal da LGPD.
      t.string   :ip_hash
      t.datetime :clicked_at, null: false
      t.timestamps
    end

    create_table :page_views do |t|
      t.references :landing_page, null: false, foreign_key: true
      t.references :short_link, foreign_key: true
      t.string   :referrer
      t.string   :ip_hash
      t.datetime :viewed_at, null: false
      t.timestamps
    end

    create_table :leads do |t|
      t.references :project, null: false, foreign_key: true
      t.references :landing_page, foreign_key: true
      t.references :post, foreign_key: true
      t.references :short_link, foreign_key: true
      t.string :name
      t.string :phone
      t.string :email
      t.text   :message
      t.string :status, null: false, default: "novo"
      t.string :source, null: false, default: "form"   # form | manual
      # LGPD: guardar o texto aceito, não só um booleano — é o que prova
      # com o que a pessoa concordou.
      t.text     :consent_text
      t.datetime :consent_at
      t.datetime :anonymized_at
      t.timestamps
    end
    add_index :leads, [ :project_id, :status ]
  end
end
