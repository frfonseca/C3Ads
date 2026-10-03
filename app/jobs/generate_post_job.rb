# Gera o conteúdo de um post e o devolve para a fila de revisão.
#
# Nunca publica: o destino final é sempre `pending_review`, que é o que mantém
# a invariante de aprovação também no caminho automático dos gatilhos.
class GeneratePostJob < ApplicationJob
  queue_as :default

  def perform(post_id, context: nil, feedback: nil)
    post = Post.find(post_id)
    return unless post.may_start_generation?

    post.start_generation!

    assets = assets_for(post)
    result = Content::Generator.build(post.project)
                               .generate_post(assets:, context:, feedback:)

    apply!(post, result, assets)
    post.finish_generation!
  rescue StandardError => e
    Rails.logger.error("[GeneratePostJob] post=#{post_id} #{e.class}: #{e.message}")
    post&.fail_generation! if post&.may_fail_generation?
    raise
  end

  private

  def assets_for(post)
    existing = post.assets.to_a
    return existing if existing.any?

    # Sem seleção explícita, usa as fotos menos usadas recentemente — é o que
    # evita repetir a mesma imagem toda semana na lavanderia.
    post.project.assets.photos.usable.least_recently_used
        .limit(Content::Generator::MAX_IMAGES_PER_CALL).to_a
  end

  def apply!(post, result, assets)
    post.caption  = result["caption"]
    post.hashtags = Array(result["hashtags"])
    post.generation_meta = result.except("caption", "hashtags")
    post.regeneration_count += 1 if post.regeneration_count.to_i.positive? || post.caption_previously_changed?

    rebuild_media!(post, result, assets)
    post.save!
    assets.each(&:record_use!)
  end

  def rebuild_media!(post, result, assets)
    order = Array(result["order"]).presence || assets.each_with_index.map { |a, i| { "asset_id" => a.id, "position" => i } }
    by_id = assets.index_by(&:id)

    post.post_media.destroy_all
    order.each_with_index do |entry, index|
      asset = by_id[entry["asset_id"]] || assets[index]
      next unless asset

      post.post_media.build(asset:, position: index, alt_text: Array(result["alt_texts"])[index])
    end
  end
end
