class CreatePublishingTables < ActiveRecord::Migration[8.1]
  def change
    create_table :publish_attempts do |t|
      t.references :post, null: false, foreign_key: true
      t.string  :step, null: false          # container | child_container | status | publish
      t.string  :outcome, null: false       # success | error
      t.string  :container_id
      t.text    :request_summary
      t.text    :response_summary
      t.text    :error_message
      t.timestamps
    end
    add_index :publish_attempts, [ :post_id, :step ]

    create_table :post_metrics do |t|
      t.references :post, null: false, foreign_key: true
      t.integer  :reach
      t.integer  :impressions
      t.integer  :likes
      t.integer  :comments
      t.integer  :saved
      t.integer  :shares
      t.datetime :collected_at, null: false
      t.timestamps
    end
    # Histórico, não sobrescrita: os números só estabilizam depois de ~48h.
    add_index :post_metrics, [ :post_id, :collected_at ], unique: true
  end
end
