class CreateAdTables < ActiveRecord::Migration[8.1]
  def change
    create_table :ad_targetings do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :name
      t.string  :countries, array: true, default: [ "BR" ]
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :radius_km
      t.integer :age_min
      t.integer :age_max
      t.string  :genders, array: true, default: []
      t.string  :interests, array: true, default: []
      t.timestamps
    end

    create_table :ad_campaigns do |t|
      t.references :project, null: false, foreign_key: true
      t.references :post, foreign_key: true
      t.references :ad_targeting, foreign_key: true
      t.string  :name, null: false
      t.string  :objective, null: false, default: "OUTCOME_TRAFFIC"
      # HOUSING por padrão em projetos de imóvel: falhar para o lado seguro.
      t.string  :special_ad_category, null: false, default: "NONE"
      t.string  :state, null: false, default: "draft"
      t.integer :daily_budget_cents
      t.string  :meta_campaign_id
      t.string  :meta_ad_set_id
      t.string  :meta_ad_id
      t.datetime :activated_at
      t.timestamps
    end
  end
end
