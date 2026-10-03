# Fase 1 — Fundação, modelos, invariante de aprovação

## Objetivo

Modelar o núcleo do domínio e tornar a regra "nada vai ao ar sem revisão
humana" impossível de violar pelo código — não só pela interface.

## Escopo

- Modelos `Business` (imóvel, lavanderia), `Post` e o que for necessário para
  ligá-los (ex.: `Media` com Active Storage para a foto de origem).
- State machine de `Post`: `draft → pending_review → approved → published`,
  com `rejected` saindo de `pending_review`. Implementação sem gem extra é
  preferível; se usar gem, justifique em ADR.
- Guard: transição para `published` exige `approved` e registra quem aprovou
  (`approved_by`, `approved_at`).
- Cop customizado `C3Ads/PostStatusBypass` em `lib/rubocop/cop/c3ads/`,
  habilitado no `.rubocop.yml`, que acusa escrita direta de status em posts
  (`update_column(:status`, `update_columns(status:`, `update(status: :published)`,
  `update_all(status:`, `insert_all`/`upsert_all` em `Post`). A mensagem do cop
  deve dizer **como** corrigir (ex.: "use `post.publish!`; exige aprovação").
- Seeds com um negócio de cada tipo e posts em estados variados.

## Fora de escopo

Geração via LLM, UI de aprovação, qualquer chamada ao Instagram (fases 2–4).

## Critérios de aceite

1. Publicar um post em `draft`, `pending_review` ou `rejected` levanta erro e
   não altera o banco.
2. Publicar um post `approved` funciona e preserva `approved_by`/`approved_at`.
3. Uma constraint no banco (check constraint) impede `status = 'published'` com
   `approved_at` nulo — protege até contra SQL direto.
4. O cop `C3Ads/PostStatusBypass` tem testes próprios cobrindo cada padrão
   proibido e um caso permitido.
5. `bin/ci` verde.

## Notas para o agente

Escreva primeiro os testes dos critérios 1–4 e veja-os falhar. O critério 3 é o
sensor mais forte do projeto; não o troque por validação só em Ruby.
