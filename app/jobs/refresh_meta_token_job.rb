# Renova o token de longa duração da Meta antes de vencer.
#
# É a falha silenciosa mais provável do sistema: o token dura ~60 dias e, se
# vencer, só volta refazendo o OAuth na mão — e o sintoma é o sistema parar
# de publicar sem erro visível.
class RefreshMetaTokenJob < ApplicationJob
  queue_as :critical

  def perform
    Account.needing_token_refresh.find_each do |account|
      refresh(account)
    end
  end

  private

  def refresh(account)
    if account.token_expiring_soon?
      SystemAlert.raise_alert(
        kind: "meta_token_expiring",
        severity: "critical",
        message: "O token da conta #{account.name} vence em #{dias(account)} dias.",
        context: { account_id: account.id, expires_at: account.token_expires_at }
      )
    end

    return unless ENV["META_APP_ID"].present? && ENV["META_APP_SECRET"].present?

    response = exchange(account)
    account.update!(
      access_token: response.fetch("access_token"),
      token_expires_at: Time.current + response.fetch("expires_in", 60.days.to_i).to_i.seconds
    )
  rescue StandardError => e
    SystemAlert.raise_alert(
      kind: "meta_token_refresh_failed",
      severity: "critical",
      message: "Falha ao renovar o token de #{account.name}: #{e.message}. " \
               "É preciso refazer a autorização no painel.",
      context: { account_id: account.id }
    )
  end

  def dias(account) = ((account.token_expires_at - Time.current) / 1.day).round

  def exchange(account)
    conn = Faraday.new(url: "https://graph.facebook.com") do |f|
      f.response :json
      f.adapter Faraday.default_adapter
    end
    response = conn.get("/v21.0/oauth/access_token",
                        grant_type: "fb_exchange_token",
                        client_id: ENV.fetch("META_APP_ID"),
                        client_secret: ENV.fetch("META_APP_SECRET"),
                        fb_exchange_token: account.access_token)
    raise "resposta #{response.status}" unless response.success?

    response.body
  end
end
