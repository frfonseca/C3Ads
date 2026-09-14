# Separado de CreateCoreTables porque o schema.rb é gerado em ordem alfabética:
# `brands` viria antes de `assets`, e as foreign keys falhariam no db:schema:load.
class AddBrandAssetReferences < ActiveRecord::Migration[8.1]
  def change
    add_reference :brands, :logo_asset, foreign_key: { to_table: :assets }
    add_reference :brands, :logo_dark_asset, foreign_key: { to_table: :assets }
    add_reference :brands, :favicon_asset, foreign_key: { to_table: :assets }
  end
end
