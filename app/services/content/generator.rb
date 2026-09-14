module Content
  # Geração de legendas e conteúdo de página via LLM, provider-agnóstico.
  #
  # O provedor é configurável por projeto e o prompt é montado a partir da
  # Brand — tom de voz, termos a preferir e termos proibidos.
  class Generator
    class Error < StandardError; end

    # Limites dos provedores de vision: acima de 20 imagens num request, a
    # Anthropic aplica restrição de dimensão mais estrita a todas as imagens.
    MAX_IMAGES_PER_CALL = 20
    MAX_IMAGE_LONG_EDGE = 2000

    def self.build(project = nil)
      if ENV["LLM_FAKE"] == "true" || !credentials_present?
        FakeGenerator.new(project)
      else
        new(project)
      end
    end

    def self.credentials_present?
      %w[ANTHROPIC_API_KEY GEMINI_API_KEY OPENAI_API_KEY].any? { |k| ENV[k].present? }
    end

    def initialize(project)
      @project = project
    end

    def generate_post(assets:, context: nil, feedback: nil)
      chat = build_chat
      chat.with_schema(Content::Schemas::CarouselPost)
          .ask(post_prompt(context, feedback), with: attachments(assets))
          .content
    end

    private

    def build_chat
      chat = RubyLLM.chat(model: @project&.llm_model, provider: @project&.llm_provider&.to_sym)
      fallbacks = @project&.llm_fallbacks.to_a
      chat = chat.with_fallbacks(*fallbacks) if fallbacks.any?
      chat.with_instructions(system_prompt)
    end

    # A Brand é estável entre chamadas — vai no bloco cacheável do prompt.
    def system_prompt
      [
        "Você escreve conteúdo para Instagram de um negócio brasileiro.",
        "Escreva em português do Brasil, natural e específico. Evite clichê publicitário.",
        @project&.brand&.prompt_instructions
      ].compact_blank.join("\n\n")
    end

    def post_prompt(context, feedback)
      parts = [ "Gere um post de Instagram a partir das fotos anexadas." ]
      parts << "Contexto da ocasião: #{context}" if context.present?
      parts << "Ajuste pedido pelo revisor: #{feedback}" if feedback.present?
      parts.join("\n")
    end

    def attachments(assets)
      Array(assets).first(MAX_IMAGES_PER_CALL).map(&:file)
    end
  end
end
