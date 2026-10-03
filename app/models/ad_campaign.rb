class AdCampaign < ApplicationRecord
  include AASM

  CATEGORIES = %w[NONE HOUSING EMPLOYMENT FINANCIAL_PRODUCTS_SERVICES ISSUES_ELECTIONS_POLITICS].freeze

  belongs_to :project
  belongs_to :post, optional: true
  belongs_to :ad_targeting, optional: true

  validates :special_ad_category, inclusion: { in: CATEGORIES }, allow_nil: false
  validates :daily_budget_cents, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :default_category, on: :create

  aasm column: :state do
    state :draft, initial: true
    state :created_paused, :active, :paused, :failed

    # Nunca vai direto a `active`: criar e ativar são passos separados, porque
    # ativar gasta dinheiro.
    event :mark_created do
      transitions from: :draft, to: :created_paused
    end

    event :activate do
      transitions from: [ :created_paused, :paused ], to: :active
      after { update_column(:activated_at, Time.current) }
    end

    event :pause do
      transitions from: :active, to: :paused
    end

    event :mark_failed do
      transitions from: [ :draft, :created_paused ], to: :failed
    end
  end

  def housing? = special_ad_category == "HOUSING"

  def daily_budget_brl = daily_budget_cents.to_i / 100.0

  private

  # Projeto de imóvel assume HOUSING salvo escolha explícita. A aplicabilidade
  # ao Brasil não está confirmada na doc da Meta, então falhamos para o lado
  # seguro: restringir a mais não é rejeitado, restringir a menos é.
  def default_category
    # nil = não informado → projeto de imóvel assume HOUSING.
    # "NONE" explícito é decisão do usuário e é respeitada.
    return if special_ad_category.present?

    self.special_ad_category = project&.property? ? "HOUSING" : "NONE"
  end
end
