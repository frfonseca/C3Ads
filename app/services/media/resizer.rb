module Media
  # Redimensiona imagens antes de enviá-las ao LLM.
  #
  # Existe por três razões, em ordem de importância:
  # 1. Acima de 20 blocos de imagem num request, a Anthropic aplica um limite
  #    de dimensão mais estrito a TODAS as imagens e rejeita as que excederem.
  # 2. Custo: o número de tokens cresce com a área da imagem.
  # 3. Limite de 32 MB por request, que 20 fotos de celular estouram fácil.
  class Resizer
    LONG_EDGE = 2000

    def self.call(attachment, long_edge: LONG_EDGE)
      new(attachment, long_edge:).call
    end

    def initialize(attachment, long_edge: LONG_EDGE)
      @attachment = attachment
      @long_edge = long_edge
    end

    # Devolve uma variante processada; se a imagem já couber, devolve o original.
    def call
      return @attachment unless @attachment.respond_to?(:variant)
      return @attachment unless image?

      @attachment.variant(resize_to_limit: [ @long_edge, @long_edge ]).processed
    rescue StandardError => e
      # Uma foto problemática não deve derrubar a geração inteira.
      Rails.logger.warn("[Resizer] falha ao redimensionar: #{e.class}: #{e.message}")
      @attachment
    end

    private

    def image?
      @attachment.try(:content_type).to_s.start_with?("image/")
    end
  end
end
