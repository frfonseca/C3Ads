# C3Ads

Esteira de publicação e anúncios para Instagram, para dois negócios próprios:
a venda de um imóvel e uma lavanderia.

O fluxo é sempre o mesmo: **foto ou evento entra → conteúdo é gerado → é aprovado
por uma pessoa → publica no Instagram → opcionalmente vira anúncio pago.**

## Princípio central

Nada vai ao ar sem revisão humana. Isso não é regra de interface — é invariante
de domínio, garantida por guards na state machine de `Post` e provada em
`spec/models/post_spec.rb`.

## Como rodar

Requisitos: Ruby 3.4.8, Docker.

```bash
docker compose up -d          # Postgres (5433) e Redis (6380)
bin/rails db:prepare
bin/rails server              # painel em http://app.lvh.me:3000
bundle exec sidekiq           # jobs
```

`lvh.me` resolve para 127.0.0.1 com qualquer subdomínio — é assim que se testa
o roteamento localmente sem mexer em `/etc/hosts`.

As portas 5433/6380 são usadas porque já há um Postgres local na 5432.

## Sem credenciais? Funciona mesmo assim

Todos os clientes externos têm modo fake, ativado automaticamente quando não há
credencial. A esteira inteira roda e é testável antes de existir conta no
Instagram ou chave de LLM.

```bash
META_FAKE=true LLM_FAKE=true bin/rails server   # força o modo fake
```

## Estrutura

| Caminho | O que é |
|---|---|
| `app/models/post.rb` | State machine e a invariante de aprovação |
| `app/models/asset.rb` | Biblioteca do projeto; `visibility` controla exposição pública |
| `app/models/brand.rb` | Identidade visual e verbal, aplicada automaticamente |
| `app/services/meta/` | Publicação e anúncios, com fakes |
| `app/services/content/` | Geração via LLM, provider-agnóstico |
| `lib/landing_page_constraint.rb` | Resolve subdomínio → landing page |

## Domínios

| Host | Serve |
|---|---|
| `app.<dominio>` | Painel, autenticado |
| `<slug>.<dominio>` | Landing pages públicas |
| `<dominio>/r/:slug` | Link curto rastreável |

O cookie de sessão fica preso a `app.` e nunca ao domínio-pai — caso contrário
seria enviado às páginas públicas.

## Testes

```bash
bundle exec rspec
```

## Notas de compatibilidade

- **`json` fixada em 2.x**: a série 3.0 removeu o segundo argumento posicional de
  `JSON.parse`, que o Rails 8.1 ainda usa em `ActiveSupport::JSON.decode`. Com
  json 3.x, qualquer coluna `jsonb` levanta `ArgumentError`.
- **Defaults de `jsonb` ficam no modelo**, não no banco: o schema dumper do
  Rails 8.1 omite silenciosamente qualquer tabela cuja coluna jsonb tenha
  `DEFAULT`, produzindo um `schema.rb` incompleto.
