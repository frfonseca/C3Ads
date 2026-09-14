module Content
  module Schemas
    # Schema do post gerado. Usado com `with_schema` para forçar JSON válido
    # em qualquer um dos três provedores.
    CarouselPost = {
      type: "object",
      properties: {
        caption: { type: "string", description: "Legenda do post, pt-BR" },
        hashtags: { type: "array", items: { type: "string" }, maxItems: 30 },
        order: {
          type: "array",
          description: "Fotos na ordem ideal do carrossel",
          items: {
            type: "object",
            properties: {
              asset_id: { type: "integer" },
              position: { type: "integer" },
              reason: { type: "string" }
            },
            required: %w[asset_id position],
            additionalProperties: false
          }
        },
        cover_index: { type: "integer" },
        alt_texts: { type: "array", items: { type: "string" } }
      },
      required: %w[caption hashtags order],
      additionalProperties: false
    }.freeze
  end
end
