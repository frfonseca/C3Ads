module Notifier
  # Alertas no celular. Bot gratuito do @BotFather; sem token, só registra log.
  class Telegram
    API = "https://api.telegram.org".freeze

    EMOJI = { "info" => "ℹ️", "warning" => "⚠️", "critical" => "🚨" }.freeze

    def initialize(token: ENV["TELEGRAM_BOT_TOKEN"], chat_id: ENV["TELEGRAM_CHAT_ID"])
      @token = token
      @chat_id = chat_id
    end

    def configured? = @token.present? && @chat_id.present?

    # Best-effort por design: notificação é conveniência, não o registro.
    def deliver(alert)
      unless configured?
        Rails.logger.info("[Telegram fake] #{alert.severity}: #{alert.message}")
        return false
      end

      response = connection.post("/bot#{@token}/sendMessage",
                                 chat_id: @chat_id, text: format_message(alert),
                                 parse_mode: "HTML")
      alert.update_columns(notified_at: Time.current) if response.success?
      response.success?
    rescue StandardError => e
      Rails.logger.warn("[Telegram] falha ao enviar: #{e.class}: #{e.message}")
      false
    end

    private

    def format_message(alert)
      "#{EMOJI.fetch(alert.severity, '')} <b>#{alert.kind}</b>\n#{alert.message}"
    end

    def connection
      @connection ||= Faraday.new(url: API) do |f|
        f.request :url_encoded
        f.response :json
        f.options.timeout = 10
        f.adapter Faraday.default_adapter
      end
    end
  end
end
