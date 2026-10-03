class PostMedium < ApplicationRecord
  self.table_name = "post_media"

  belongs_to :post
  belongs_to :asset

  validates :position, uniqueness: { scope: :post_id }
end
