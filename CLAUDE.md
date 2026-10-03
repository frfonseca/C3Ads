# C3Ads — guia para agentes

Esteira de conteúdo para Instagram de dois negócios próprios (um imóvel à venda
e uma lavanderia): foto ou evento entra → conteúdo é gerado → **uma pessoa
aprova** → publica → opcionalmente vira anúncio pago. Visão geral no `README.md`.

## Stack

Ruby 3.3.6 · Rails 8.1 · PostgreSQL 16 · Solid Queue/Cache/Cable (sem Redis) ·
Hotwire + importmap · Minitest · RuboCop (rails-omakase).

## Comandos

- `bin/setup --skip-server` — instala gems e prepara o banco.
- `bin/ci` — **o portão**: RuboCop, bundler-audit, importmap audit, Brakeman,
  testes e seeds (definido em `config/ci.rb`). Uma tarefa só está pronta com
  `bin/ci` verde.
- `bin/rails test` / `bin/rails test test/models/post_test.rb:42` — testes.
- `bin/rubocop -a` — estilo.
- `bin/dev` — sobe a app em desenvolvimento.

## Invariantes de domínio (nunca violar)

1. **Nada vai ao ar sem aprovação humana.** Um `Post` só chega a `published`
   passando pela state machine, cujo guard exige `approved`. Nunca contorne:
   nada de `update_column(:status, …)`, `update(status: :published)`,
   `insert_all`/`upsert_all` em posts, nem SQL direto. Se precisar publicar em
   teste, aprove antes.
2. **Nenhuma chamada real a serviço externo fora de produção.** LLMs (Claude,
   Gemini, OpenAI) e Instagram/Meta são acessados só por adapters em
   `app/adapters/`, com fake para dev e teste. Publicar de verdade exige
   `PUBLISHING_ENABLED=true`, que nunca é ligado fora de produção.
3. **Dinheiro tem teto.** Geração via LLM e anúncios pagos respeitam teto de
   custo configurado; quando não houver teto, não gaste.

## Como trabalhar aqui

- Cada fase do `README.md` tem spec em `docs/fases/NN-*.md` com critérios de
  aceite. Leia a spec antes de começar; escreva os testes dos critérios primeiro.
- Fora do escopo da spec → não implemente; anote no PR como sugestão.
- Decisões de arquitetura ficam em `docs/adr/`. Não reabra uma decisão sem
  propor um ADR novo.
- Um PR por fase (ou fatia de fase), preenchendo `.github/pull_request_template.md`.
- Código, nomes de classes e métodos em inglês; textos de UI, docs e commits em
  português.

## Proibido

- Ler ou imprimir segredos: `.env*`, `config/*.key`, `bin/rails credentials:show`.
- Pular, desativar ou marcar como `skip` um teste para ficar verde.
- `git push --force` em branch que não é sua.
- Adicionar gem sem justificar no PR.

## Quando errar de novo

Se você (agente) ou um revisor achar um erro que pode se repetir, a correção
inclui o harness: uma regra aqui, um teste, um cop ou um hook. Registre em
`docs/harness-log.md`.
