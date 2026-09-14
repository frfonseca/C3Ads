class CreateTriggers < ActiveRecord::Migration[8.1]
  def change
    create_table :triggers do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :kind, null: false            # weather | schedule | manual
      t.string  :name
      t.jsonb   :condition
      t.integer :cooldown_hours, null: false, default: 24
      t.boolean :active, null: false, default: true
      t.datetime :last_fired_at
      t.timestamps
    end
    add_index :triggers, [ :project_id, :kind ]

    create_table :trigger_events do |t|
      t.references :trigger, null: false, foreign_key: true
      t.references :post, foreign_key: true
      t.boolean :fired, null: false, default: false
      t.text    :reason
      t.jsonb   :context
      t.datetime :evaluated_at, null: false
      t.timestamps
    end
    add_index :trigger_events, [ :trigger_id, :evaluated_at ]
  end
end
