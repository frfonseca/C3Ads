class CreateVideoRenders < ActiveRecord::Migration[8.1]
  def change
    create_table :video_renders do |t|
      t.references :post, null: false, foreign_key: true
      t.references :asset, foreign_key: true   # o vídeo resultante
      t.string  :state, null: false, default: "pending"
      t.jsonb   :spec
      t.integer :duration_seconds
      t.text    :error_message
      t.timestamps
    end
  end
end
