class Project < ApplicationRecord
  KINDS = %w[property local_business generic].freeze

  belongs_to :account, optional: true

  has_one  :brand, dependent: :destroy
  has_many :assets, dependent: :destroy
  has_many :asset_collections, dependent: :destroy
  has_many :posts, dependent: :destroy

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }

  after_create :ensure_brand

  scope :active, -> { where(active: true) }

  def property? = kind == "property"

  private

  def ensure_brand
    create_brand! unless brand
  end
end
