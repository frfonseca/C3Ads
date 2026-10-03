class Trigger < ApplicationRecord
  KINDS = %w[weather schedule manual].freeze

  belongs_to :project
  has_many :trigger_events, dependent: :destroy

  attribute :condition, ActiveRecord::Type::Json.new, default: -> { {} }

  validates :kind, inclusion: { in: KINDS }

  scope :active, -> { where(active: true) }
  # Manual não é avaliado pelo cron: é acionado pelo controller.
  scope :automatic, -> { active.where.not(kind: "manual") }

  def evaluator = Triggers::Registry.build(self)

  # Sem debounce, uma semana de chuva geraria sete posts iguais.
  def in_cooldown?
    return false if last_fired_at.blank? || cooldown_hours.to_i.zero?

    last_fired_at > cooldown_hours.hours.ago
  end
end
