class LandingMedium < ApplicationRecord
  self.table_name = "landing_media"
  belongs_to :landing_page
  belongs_to :asset
end
