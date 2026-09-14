module Triggers
  # Condição: { cron: "0 10 * * 2" } — toda terça às 10h.
  class Schedule < Base
    def fired?
      expression = @condition["cron"]
      return false if expression.blank?

      parsed = Fugit.parse_cron(expression)
      return false if parsed.nil?

      # Dispara se houve uma ocorrência desde a última avaliação.
      previous = parsed.previous_time(Time.current).to_t
      previous > (@trigger.last_fired_at || 1.year.ago)
    rescue StandardError => e
      Rails.logger.warn("[Triggers::Schedule] cron inválido: #{e.message}")
      false
    end

    def context = { "schedule" => { "cron" => @condition["cron"] } }

    def reason = "agenda #{@condition['cron']}"
  end
end
