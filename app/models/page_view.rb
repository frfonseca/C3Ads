class PageView < ApplicationRecord
  belongs_to :landing_page
  belongs_to :short_link, optional: true
end
