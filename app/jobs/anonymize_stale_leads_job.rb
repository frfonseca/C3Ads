# Retenção LGPD: lead sem interação há 12 meses perde a PII e mantém a
# estatística. Dado guardado para sempre é passivo, não patrimônio.
class AnonymizeStaleLeadsJob < ApplicationJob
  queue_as :default

  def perform
    Lead.stale.find_each(&:anonymize!)
  end
end
