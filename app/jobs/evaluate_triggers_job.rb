# Avalia os gatilhos automáticos de hora em hora.
#
# Nunca publica: cria o post em pending_review, que é o que mantém a invariante
# de aprovação também no caminho automático.
class EvaluateTriggersJob < ApplicationJob
  queue_as :default

  def perform
    Trigger.automatic.includes(:project).find_each { |trigger| evaluate(trigger) }
  end

  private

  def evaluate(trigger)
    evaluator = trigger.evaluator

    if trigger.in_cooldown?
      record(trigger, evaluator, fired: false, reason: "em cooldown")
      return
    end

    unless evaluator.fired?
      record(trigger, evaluator, fired: false, reason: "condição não atendida")
      return
    end

    post = create_post!(trigger, evaluator)
    trigger.update_columns(last_fired_at: Time.current)
    record(trigger, evaluator, fired: true, post:)

    SystemAlert.raise_alert(
      kind: "trigger_fired", severity: "info",
      message: "#{trigger.project.name}: #{evaluator.reason}. Um post aguarda sua aprovação.",
      context: { trigger_id: trigger.id, post_id: post.id }
    )
  rescue StandardError => e
    Rails.logger.error("[EvaluateTriggersJob] trigger=#{trigger.id} #{e.class}: #{e.message}")
    record(trigger, nil, fired: false, reason: "erro: #{e.message}")
  end

  def create_post!(trigger, evaluator)
    post = trigger.project.posts.create!(media_type: "carousel", account: trigger.project.account)
    GeneratePostJob.perform_later(post.id, context: humanize(evaluator.context))
    post
  end

  # O contexto do gatilho vira texto para o prompt: "previsão de 80% de chance
  # de chuva nas próximas 24 horas".
  def humanize(context)
    parts = []
    parts << context.dig("weather", "description")
    parts << context["note"]
    parts.compact_blank.join(". ").presence
  end

  def record(trigger, evaluator, fired:, reason: nil, post: nil)
    trigger.trigger_events.create!(
      fired:, post:,
      reason: reason || evaluator&.reason,
      context: evaluator&.context || {},
      evaluated_at: Time.current
    )
  end
end
