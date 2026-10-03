class PublishAttempt < ApplicationRecord
  belongs_to :post

  scope :successful, -> { where(outcome: "success") }
end
