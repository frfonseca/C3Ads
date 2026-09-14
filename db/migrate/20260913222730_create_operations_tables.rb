class CreateOperationsTables < ActiveRecord::Migration[8.1]
  def change
    create_table :generation_costs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :post, foreign_key: true
      t.string  :provider
      t.string  :model
      t.integer :input_tokens
      t.integer :output_tokens
      t.decimal :usd, precision: 10, scale: 5, default: 0
      t.timestamps
    end
    add_index :generation_costs, [ :project_id, :created_at ]

    create_table :system_alerts do |t|
      t.string  :kind, null: false
      t.string  :severity, null: false, default: "warning"
      t.text    :message, null: false
      t.jsonb   :context
      t.datetime :notified_at
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :system_alerts, [ :kind, :resolved_at ]
  end
end
