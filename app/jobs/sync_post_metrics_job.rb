# Lê as métricas de volta do Instagram e fecha o ciclo de aprendizado.
#
# Sem isso o sistema publica no escuro: os cliques do link curto dizem quem
# se interessou, mas só os insights dizem quantos viram e quantos salvaram.
class SyncPostMetricsJob < ApplicationJob
  queue_as :default

  # Reels e feed expõem métricas com nomes diferentes na API.
  FEED_METRICS  = %w[reach impressions likes comments saved shares].freeze
  REEL_METRICS  = %w[reach plays likes comments saved shares].freeze

  WINDOW = 30.days

  def perform(post_id = nil)
    scope = post_id ? Post.where(id: post_id) : recently_published
    scope.find_each { |post| sync(post) }
  end

  private

  def recently_published
    Post.where(state: "published").where(published_at: WINDOW.ago..).where.not(ig_media_id: nil)
  end

  def sync(post)
    client = Meta::GraphClient.build(post.account)
    metrics = post.media_type == "reel" ? REEL_METRICS : FEED_METRICS
    data = client.media_insights(post.ig_media_id, metrics)

    values = Array(data["data"]).each_with_object({}) do |entry, acc|
      acc[entry["name"]] = entry.dig("values", 0, "value")
    end

    # Uma linha por coleta: os números mudam nas primeiras 48h, e sobrescrever
    # perderia a evolução.
    post.post_metrics.create!(
      reach: values["reach"],
      impressions: values["impressions"] || values["plays"],
      likes: values["likes"],
      comments: values["comments"],
      saved: values["saved"],
      shares: values["shares"],
      collected_at: Time.current.beginning_of_hour
    )
  rescue ActiveRecord::RecordNotUnique
    # Já coletado nesta hora; nada a fazer.
  rescue StandardError => e
    Rails.logger.warn("[SyncPostMetricsJob] post=#{post.id} #{e.class}: #{e.message}")
  end
end
