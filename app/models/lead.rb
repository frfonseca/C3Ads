class Lead < ApplicationRecord
  STATUSES = %w[novo respondido visita negociação fechado perdido].freeze
  RETENTION = 12.months

  belongs_to :project
  belongs_to :landing_page, optional: true
  belongs_to :post, optional: true
  belongs_to :short_link, optional: true

  validates :status, inclusion: { in: STATUSES }
  validate :contact_present

  scope :active, -> { where(anonymized_at: nil) }
  scope :stale, -> { active.where(updated_at: ...RETENTION.ago) }

  # LGPD: apaga a PII e mantém a estatística. Dado guardado para sempre é
  # passivo, não patrimônio.
  def anonymize!
    update_columns(
      name: nil, phone: nil, email: nil, message: nil,
      consent_text: nil, anonymized_at: Time.current
    )
  end

  def anonymized? = anonymized_at.present?

  private

  def contact_present
    return if anonymized?
    return if phone.present? || email.present?

    errors.add(:base, "informe telefone ou e-mail")
  end
end
