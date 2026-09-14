class AssetCollection < ApplicationRecord
  belongs_to :project
  has_many :asset_collection_memberships, dependent: :destroy
  has_many :assets, through: :asset_collection_memberships

  validates :name, presence: true
end
