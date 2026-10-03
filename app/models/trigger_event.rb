class TriggerEvent < ApplicationRecord
  belongs_to :trigger
  belongs_to :post, optional: true

  attribute :context, ActiveRecord::Type::Json.new, default: -> { {} }

  scope :fired, -> { where(fired: true) }
end
