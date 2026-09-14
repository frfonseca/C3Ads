# C3Ads

Esteira de publicação e anúncios para Instagram, para dois negócios próprios:
a venda de um imóvel e uma lavanderia.

O fluxo é sempre o mesmo: **foto ou evento entra → conteúdo é gerado → é
aprovado por uma pessoa → publica no Instagram → opcionalmente vira anúncio
pago.**

## Princípio central

Nada vai ao ar sem revisão humana. Isso não é regra de interface — é invariante
de domínio, garantida por guards na state machine de `Post`.

## Estado

A implementação chega em nove fases, cada uma num pull request próprio. Ao fim
da Fase 4 o sistema já resolve o problema de ponta a ponta.

| Fase | Entrega |
|---|---|
| 1 | Fundação, modelos, invariante de aprovação |
| 2 | Geração via LLM (Claude, Gemini, OpenAI), aba Marca |
| 3 | Fila de aprovação, exportação manual |
| 4 | Publicação no Instagram, idempotência, métricas |
| 5 | Landing pages, link rastreável, leads, LGPD |
| 6 | Alertas, renovação de token, teto de custo |
| 7 | Slideshow em vídeo |
| 8 | Gatilhos: clima, agenda, manual |
| 9 | Anúncios pagos com restrições de imóvel |
