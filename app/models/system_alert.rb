class SystemAlert < ApplicationRecord
  SEVERITIES = %w[info warning critical].freeze

  attribute :context, ActiveRecord::Type::Json.new, default: -> { {} }

  validates :severity, inclusion: { in: SEVERITIES }

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :pending_notification, -> { where(notified_at: nil) }

  # O banco é a fonte de verdade; o Telegram é conveniência. Falha ao notificar
  # nunca derruba o job que originou o alerta.
  def self.raise_alert(kind:, message:, severity: "warning", context: {})
    alert = create!(kind:, message:, severity:, context:)
    Notifier::Telegram.new.deliver(alert)
    alert
  rescue StandardError => e
    Rails.logger.error("[SystemAlert] #{kind}: #{message} (notificação falhou: #{e.message})")
    alert
  end

  def resolve! = update!(resolved_at: Time.current)
end
