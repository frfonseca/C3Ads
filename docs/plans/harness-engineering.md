# Harness engineering no C3Ads

Notas de planejamento. Referência: [Harness engineering — martinfowler.com](https://martinfowler.com/articles/harness-engineering.html)
(o artigo não pôde ser lido do ambiente de nuvem; o resumo abaixo é de memória
e deve ser conferido com o texto).

## O modelo

- **Harness** = tudo em volta do agente que não é o modelo: instruções,
  ferramentas, verificações e ciclos de feedback. O trabalho humano passa a ser
  projetar e manter o harness.
- **Guias (feedforward)**: orientam o agente antes de agir — CLAUDE.md curto
  como índice, `docs/` como fonte da verdade, decisões registradas.
- **Sensores (feedback)**: detectam o erro depois — testes, linters,
  checagens de arquitetura, revisão.
- **Computacional** (determinístico, barato) vs **inferencial** (LLM julgando).
  Preferir computacional; inferencial onde regra não alcança.
- Regula três coisas: **manutenibilidade, arquitetura, comportamento**.
- **Qualidade à esquerda**: o sinal chega dentro do loop do agente, não só no CI.
- **Mensagem de erro é instrução**: o agente lê e corrige na direção dela.
- **Coleta de lixo contínua**: agentes agendados limpam desvios.

## Diagnóstico (2026-10-03)

Pontos fortes:

- Invariante de aprovação no modelo (`Post` + AASM), provada em spec.
- Modo fake em todos os clientes externos.
- README e commits explicam o porquê das decisões.
- Brakeman, bundler-audit, RuboCop e Dependabot já configurados.

Lacunas:

- [ ] **CI não roda testes** — nem `.github/workflows/ci.yml` nem `config/ci.rb` chamam `rspec`.
- [ ] **Agente não roda a suíte no ambiente de nuvem** — Ruby 3.3.6 instalado, projeto exige 3.4.8; sem SessionStart hook para Postgres/Redis.
- [ ] **Sem CLAUDE.md / AGENTS.md.**
- [ ] **Invariante contornável** — `post.update(state: "published")` / `update_column` passam por fora dos guards (`no_direct_assignment` desligado, nenhum cop proíbe).
- [ ] **Visibilidade de `Asset` sem guarda estrutural** — nada impede um controller público de expor asset privado.
- [ ] **Sem sinal inferencial** (revisão de PR) nem REVIEW.md.
- [ ] **Sem eval do conteúdo gerado** — termos proibidos e tom da `Brand` não são verificados.
- [ ] **WebMock não configurado** — testes podem sair para a rede.

## Necessidades, por fase

### Fase A — o agente consegue verificar o próprio trabalho

1. [ ] Job de `rspec` no CI (Postgres e Redis como services) e passo em `bin/ci`.
2. [ ] SessionStart hook: Ruby 3.4.8, `bundle install`, Postgres/Redis, `db:prepare`.
3. [ ] Testes nunca saem para a rede: `WebMock.disable_net_connect!`, fakes forçados em `test`.
4. [ ] Um comando único de "tudo verde" (`bin/ci`), igual local e CI.

### Fase B — guias

5. [ ] CLAUDE.md curto como índice: comandos, invariantes, "nunca faça", links.
6. [ ] `docs/decisions/` (ADRs: json 2.x, defaults jsonb no modelo, cookie em `app.`, ...) e `docs/plans/`.
7. [ ] REVIEW.md com o que todo PR deve respeitar.

### Fase C — sensores de arquitetura e invariantes (computacionais)

8. [ ] `aasm no_direct_assignment: true` + cop customizado contra escrita direta em `state` (mensagem: "use `approve_by!` / eventos do AASM").
9. [ ] Cop ou spec estrutural: controllers públicos só consultam `Asset` pelo escopo público.
10. [ ] Cop: HTTP só dentro de `app/services/meta` e `app/services/content`.
11. [ ] SimpleCov com piso para código novo; mutant na state machine de `Post`.

### Fase D — sensores inferenciais e loop

12. [ ] Revisão automática de PR usando REVIEW.md como critério.
13. [ ] Evals de conteúdo: termos proibidos e schema (computacional); tom da `Brand` via LLM-as-judge (agendado).
14. [ ] Hooks do Claude Code: RuboCop no arquivo editado (PostToolUse), specs afetados no Stop.

### Fase E — legibilidade e manutenção contínua

15. [ ] Agente sobe o app e verifica a interface (Playwright) e lê logs estruturados.
16. [ ] Rotina agendada de "jardinagem": docs vs código, TODOs velhos, specs lentos/flaky → PRs pequenos.

## Estratégia de testes

Objetivo: o teste existe para **pegar o agente errando**. O risco é o agente
escrever código e teste juntos, e o teste só confirmar o que o código faz.

### 1. Testes por papel, com regras de mudança diferentes

| Tipo | Exemplo | Quem pode mudar |
|---|---|---|
| Invariantes | aprovação obrigatória; asset privado nunca público; anúncio nasce `PAUSED`; cookie em `app.` | Só com decisão humana explícita |
| Contratos | fake ≡ cliente real (Meta, LLM) | Agente, se o contrato continuar valendo |
| Comportamento | fluxo foto → geração → aprovação → publicação | Agente, livremente |
| Regressão | um por bug encontrado | Nunca removido |

- [ ] Invariantes em `spec/invariants/`, protegidas: hook bloqueia edição, CI sinaliza PR que mexe na pasta, REVIEW.md trata enfraquecimento de teste como bloqueante.

### 2. Cobertura por construção, não por exemplo

- [ ] Teste exaustivo da state machine: busca sobre todos os estados/eventos do AASM sem `approve_by!` — nenhum caminho alcança `published`. Evento novo fica coberto automaticamente.
- [ ] Todas as rotas públicas × assets privados.
- [ ] Todos os métodos de criação de anúncio nascem `PAUSED`.

### 3. Fakes não podem mentir

- [ ] `shared_examples` de contrato rodando contra o fake e contra o cliente real com cassetes VCR.
- [ ] Teste de assinatura: métodos do fake têm os mesmos parâmetros do real.
- [ ] Rotina periódica de regravação de cassetes contra a API real (fora do gate de PR).

### 4. Um teste de ponta a ponta sobre os fakes

- [ ] Request spec: upload → geração → revisão → aprovação → publicação → anúncio pausado. Só um.

### 5. Conteúdo do LLM

- [ ] No CI e **em produção**: schema válido, sem termos proibidos, limite de caracteres. Termo proibido impede o post de chegar a `pending_review`.
- [ ] Fora do CI: LLM-as-judge de tom sobre casos fixos; nota acompanhada ao longo do tempo, não bloqueia merge.

### 6. Medir se o teste pega bug

- [ ] Mutation testing (mutant) em `Post`, guards de `Asset` e clientes.
- [ ] Cobertura só como piso para código novo, nunca como meta.

### 7. Sinal bom para o agente

- [ ] Suíte em menos de 1–2 minutos.
- [ ] Determinística: rede bloqueada, tempo congelado, seed fixa; flaky é bug.
- [ ] Mensagem de falha que ensina a correção (ex.: "Invariante: publicação exige approved_by/approved_at. Use Post#approve_by!, nunca update(state:)").
- [ ] Bug encontrado → teste primeiro, correção depois.

## Próximos passos

Ordem proposta:

1. rspec no CI + WebMock travando rede.
2. `spec/invariants/` com teste exaustivo da state machine e de assets privados, mais proteção contra edição.
3. Contratos fake × real com VCR.
4. Validação de termos proibidos no gerador.
5. Mutant em `Post`.
6. Teste de ponta a ponta e eval agendado de tom.

## Decisões em aberto

- Onde rodar o eval de tom (rotina agendada? qual modelo como juiz?).
- Quem regrava os cassetes VCR e com quais credenciais.
- Proteção de `spec/invariants/`: só hook local, ou também CODEOWNERS + check no CI.
