class AssetCollectionMembership < ApplicationRecord
  belongs_to :asset
  belongs_to :asset_collection

  validates :asset_id, uniqueness: { scope: :asset_collection_id }
end
