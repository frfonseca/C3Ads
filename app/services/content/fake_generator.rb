module Content
  # Devolve conteúdo determinístico e plausível, sem chamar API nenhuma.
  class FakeGenerator
    attr_reader :calls

    def initialize(project = nil)
      @project = project
      @calls = []
    end

    def generate_post(assets:, context: nil, feedback: nil)
      @calls << { method: :generate_post, assets: Array(assets).map(&:id), context:, feedback: }

      list = Array(assets)
      {
        "caption" => fake_caption(context, feedback),
        "hashtags" => (@project&.brand&.default_hashtags.presence || %w[casa lar bairro]).first(8),
        "order" => list.each_with_index.map { |a, i| { "asset_id" => a.id, "position" => i, "reason" => "ordem original" } },
        "cover_index" => 0,
        "alt_texts" => list.map { |a| "Foto #{a.id}" }
      }
    end

    private

    def fake_caption(context, feedback)
      base = "[FAKE] Conteúdo gerado sem LLM para #{@project&.name || 'projeto'}."
      base += " Contexto: #{context}." if context.present?
      base += " Revisão: #{feedback}." if feedback.present?
      base
    end
  end
end
