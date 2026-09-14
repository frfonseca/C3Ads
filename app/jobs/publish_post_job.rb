# Publica um post no Instagram: cria container(s), espera processar, publica.
#
# Idempotência é obrigatória aqui. Um retry do Sidekiq após timeout de rede
# pode publicar o mesmo post duas vezes no perfil — por isso o container é
# guardado assim que criado e reutilizado na reentrada, e a presença de
# ig_media_id encerra o job sem republicar.
class PublishPostJob < ApplicationJob
  queue_as :critical

  MAX_STATUS_CHECKS = 30
  STATUS_INTERVAL = 5.seconds

  class QuotaExceeded < StandardError; end

  def perform(post_id)
    post = Post.find(post_id)

    # Já publicado: nada a fazer. É a primeira barreira contra duplicata.
    return if post.ig_media_id.present?
    return unless post.approval_recorded?

    client = Meta::GraphClient.build(post.account)
    ensure_quota!(post, client)

    post.start_publishing! if post.may_start_publishing?

    container_id = post.ig_container_id.presence || create_container!(post, client)
    wait_until_ready!(post, client, container_id)
    publish!(post, client, container_id)
  rescue QuotaExceeded => e
    # Cota estourada não é falha: reagenda em vez de queimar o post.
    Rails.logger.warn("[PublishPostJob] #{e.message} — reagendando")
    post.update_columns(state: "scheduled")
    self.class.set(wait: 1.hour).perform_later(post_id)
  rescue StandardError => e
    record(post, step: "publish", outcome: "error", error_message: "#{e.class}: #{e.message}")
    post.update!(failure_reason: e.message)
    post.mark_failed! if post.may_mark_failed?
    raise
  end

  private

  # A doc da Meta é inconsistente sobre o limite (50 num ponto, 100 noutro),
  # então perguntamos em runtime em vez de hardcodar.
  def ensure_quota!(post, client)
    data = client.publishing_limit.dig("data", 0) || {}
    usage = data["quota_usage"].to_i
    total = data.dig("config", "quota_total").to_i
    return if total.zero? || usage < total

    raise QuotaExceeded, "cota de publicação atingida (#{usage}/#{total})"
  end

  def create_container!(post, client)
    id = post.carousel? ? create_carousel(post, client) : create_single(post, client)
    # Guardado imediatamente: é o que permite reentrar sem criar outro.
    post.update_columns(ig_container_id: id)
    id
  end

  def create_single(post, client)
    media = post.post_media.first
    response = client.create_media_container(**single_params(post, media))
    record(post, step: "container", outcome: "success", container_id: response["id"])
    response["id"]
  end

  def create_carousel(post, client)
    children = post.post_media.map do |media|
      existing = media.ig_child_container_id
      next existing if existing.present?

      child = client.create_media_container(image_url: public_url(media.asset), is_carousel_item: true)
      media.update_columns(ig_child_container_id: child["id"])
      child["id"]
    end

    response = client.create_media_container(media_type: "CAROUSEL", children: children.join(","),
                                             caption: full_caption(post))
    record(post, step: "container", outcome: "success", container_id: response["id"])
    response["id"]
  end

  def single_params(post, media)
    base = { caption: full_caption(post) }
    if post.video?
      base.merge(media_type: post.media_type == "story" ? "STORIES" : "REELS",
                 video_url: public_url(media.asset))
    else
      base.merge(image_url: public_url(media.asset))
    end
  end

  # Vídeo não fica pronto na hora: publicar cedo demais falha.
  def wait_until_ready!(post, client, container_id)
    MAX_STATUS_CHECKS.times do
      status = client.container_status(container_id)["status_code"]
      record(post, step: "status", outcome: "success", container_id:, response_summary: status)

      return if status == "FINISHED"
      raise "container em estado #{status}" if status == "ERROR"

      sleep STATUS_INTERVAL unless Rails.env.test?
    end
    raise "container não ficou pronto após #{MAX_STATUS_CHECKS} verificações"
  end

  def publish!(post, client, container_id)
    response = client.publish_container(container_id)
    post.update!(ig_media_id: response["id"], published_at: Time.current)
    post.mark_published! if post.may_mark_published?
    record(post, step: "publish", outcome: "success", container_id:, response_summary: response["id"])
  end

  def full_caption(post)
    [ post.caption, post.hashtags.map { |h| "##{h}" }.join(" ") ].compact_blank.join("\n\n")
  end

  # A Meta busca a imagem por URL, então ela precisa ser pública e estável —
  # não assinada com expiração curta, que pode vencer durante o polling.
  def public_url(asset)
    Rails.application.routes.url_helpers.rails_blob_url(
      asset.file, host: ENV.fetch("PUBLIC_HOST", "http://localhost:3000")
    )
  end

  def record(post, **attrs)
    post.publish_attempts.create!(**attrs)
  rescue StandardError => e
    Rails.logger.warn("[PublishPostJob] falha ao registrar tentativa: #{e.message}")
  end
end
