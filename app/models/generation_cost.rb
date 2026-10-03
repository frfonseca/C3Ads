class GenerationCost < ApplicationRecord
  belongs_to :project
  belongs_to :post, optional: true

  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..) }

  def self.month_total(project)
    where(project:).this_month.sum(:usd)
  end

  # O risco real não é o uso normal — é bug em loop de regeneração.
  def self.limit_reached?(project)
    limit = project.monthly_cost_limit_usd
    return false if limit.blank? || limit.zero?

    month_total(project) >= limit
  end
end
