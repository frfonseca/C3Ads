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

### 0. Decisão: integração primeiro (2026-10-03)

Testes de integração são o padrão; teste unitário é a última escolha.

- **Entrada pela borda do sistema**: request specs (HTTP no painel, landing pages, `/r/:slug`) e jobs executados de verdade. Poucos system specs com navegador para a tela de aprovação.
- **Tudo real por dentro**: Postgres, Active Storage, AASM, jobs (`perform_enqueued_jobs` / Sidekiq inline), clientes `Meta::*` e `Content::Generator` reais.
- **Substituir só na fronteira de rede**: em vez de trocar o cliente pelo fake em memória, o HTTP é interceptado por um **fake da Meta em Rack** (via `WebMock.stub_request(...).to_rack`), com estado: containers que passam por `IN_PROGRESS → FINISHED`, erros por código, cota. Assim o código do cliente real também é testado.
- **Outside-in**: o fluxo de posts ainda não existe (rotas `approve`/`reject`/`regenerate` sem controller, nenhum job). Escrever primeiro o teste de integração do fluxo e construir até ele passar.
- **Exceções onde unitário/estrutural ainda vale**: busca exaustiva na state machine, combinatória das regras de HOUSING, validação de schema da saída do LLM — combinatória demais para cobrir por HTTP. Mesmo assim, cada invariante tem também seu teste de integração.
- **Diagnóstico na falha**: quando um teste de integração falha, imprimir as requisições recebidas pelo fake da Meta, a sequência de estados do post e o log relevante — o agente precisa achar a causa sem depurar.
- **Velocidade**: transações por teste, tempo congelado (sem `sleep` no polling de container), execução paralela quando a suíte crescer.
- **Mutation testing**: rodar agendado, não por PR, porque integração é mais lenta.

Exemplos de invariantes reescritas como integração:

- [ ] `POST /projects/:id/posts/:id/approve` sem usuário logado, ou publicar post não aprovado → recusa **e o fake da Meta não recebeu nenhuma chamada**.
- [ ] Landing page pública nunca devolve URL de asset privado (inspecionar o HTML/redirects).
- [ ] Login no painel → `Set-Cookie` com `domain=app.<dominio>` (hoje o spec só lê a configuração).
- [ ] Criar anúncio pelo fluxo → o fake da Meta recebeu `status=PAUSED` em campanha, ad set e ad.

### 0.1 Pipelines e branches (2026-10-03)

Decisões:

- **PR é sempre contra `main`.** Nunca contra `staging`.
- **`staging` é descartável**: recebe a branch de trabalho por script, para ver
  mudanças rodando juntas no ambiente de staging. Ninguém parte dela para
  trabalhar e ela nunca é mergeada em lugar nenhum.
  - `bin/staging-push` — junta (merge) a branch atual em `staging`; `--replace` faz `staging` virar exatamente a branch atual.
  - `bin/staging-reset` — volta `staging` para `main`, mostrando o que será descartado (`--yes` pula a confirmação).
- **`main` acumula vários PRs mergeados e vai para produção num único deploy**, depois da suíte completa e de aprovação humana.

Situação: nenhum ambiente existe ainda (nem staging, nem produção). O desenho
abaixo é o alvo; a parte de CI pode ser construída antes dos servidores.

```
feature ──bin/staging-push──▶ staging ──[suíte rápida]──▶ deploy staging

feature ──PR──[suíte rápida]──merge──▶ main ──[Gate 1: suíte completa]──[Gate 2: aprovação]──▶ deploy produção ──▶ smoke + rollback
                                        (acumula vários PRs)
```

Gates:

- [ ] **Push em `staging`**: suíte rápida; se verde, deploy automático no staging.
- [ ] **PR → `main` (alvo < 5 min)**: suíte rápida — lint, Brakeman, auditorias, **todas as invariantes em integração**, request specs principais, contratos com o fake da Meta em Rack. Bloqueia o merge.
- [ ] **Gate 1 — push em `main`**: suíte completa (+ system specs com navegador, ponta a ponta, evals determinísticos do LLM, smoke contra staging) com `concurrency: cancel-in-progress`, sempre no SHA mais recente — o acúmulo de PRs acontece sozinho.
- [ ] **Gate 2 — produção**: GitHub Environment `production` com aprovação obrigatória; só aceita SHA com Gate 1 verde; Kamal faz o deploy daquele SHA; health check; `kamal rollback` se falhar.
- [ ] **Agendado, não bloqueia**: regravar cassetes, LLM-as-judge de tom, mutation testing.
- [ ] Separação das suítes por tag do RSpec (`:full`); o rápido roda `--tag ~full`.

Regras:

- **Invariante nunca fica só na suíte lenta**: o que causa dano irreversível (publicar sem aprovação, anúncio ativo, asset privado público, cookie no domínio-pai) bloqueia já o PR.
- **`main` sempre verde na suíte rápida**: agentes partem dela.
- **Gate 1 vermelho para a fila**: corrigir antes de novos merges; achar o culpado com o diagnóstico do teste + `git bisect run` desde o último SHA verde.
- **`staging` nunca entra em `main`**: check no PR que falha se a branch de origem for `staging`. `staging` não tem proteção contra force push (os scripts reescrevem).
- **Teste flaky na suíte completa é bug**, não motivo para re-rodar até passar.

Ambientes (a criar):

- [ ] Kamal com dois destinos: `config/deploy.staging.yml` e `config/deploy.production.yml`.
- [ ] Staging usa os fakes até haver conta de teste da Meta.

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

## Contratos com APIs externas

O contrato tem três lados: o que **enviamos**, o que **recebemos** e as
**regras da plataforma**. Ele precisa estar escrito uma vez, em código, e ser
usado pelo cliente real, pelo fake e pelos testes.

### Problemas encontrados

- [ ] **Fakes aceitam qualquer coisa** — `FakeMarketingClient#create_campaign(**params)` aceita chamada sem `name:`/`objective:`; o real quebraria. Teste passa, produção falha.
- [ ] **Fakes só têm caminho feliz** — `container_status` sempre `FINISHED`; nunca `IN_PROGRESS`, `ERROR`, `EXPIRED`, token expirado, cota estourada.
- [ ] **Rate limit detectado por HTTP 429** — a Meta costuma sinalizar limite com HTTP 400 e código de erro (4, 17, 32, 613...). Conferir na doc e classificar por `error.code`, não por status.
- [ ] **Regras de HOUSING declaradas mas não aplicadas** — `HOUSING_MIN_RADIUS_KM` e `HOUSING_BLOCKED_TARGETING` não são usadas em lugar nenhum.
- [ ] **Versão da Graph API fixa em v21.0** — versões da Meta expiram; conferir a data de descontinuação da v21.0.
- [ ] **Saída do LLM não é validada localmente** — confia-se no `with_schema` do provedor; nada checa se `asset_id` pertence às fotos enviadas, posições únicas, `cover_index` no intervalo.
- [ ] **ruby_llm 1.16 → 2.0 (major) mergeado sem testes no CI** — não se sabe se `with_schema`/`with_fallbacks` continuam iguais.

### Estratégia

1. [ ] **Contrato como código, fonte única**: schema de request (validado antes do HTTP, no real *e* no fake) e parsing da resposta para objetos de valor (`Meta::Container`, `Meta::PublishResult`...), não hashes crus. Fake devolve os mesmos objetos.
2. [ ] **Regras da plataforma como validação**: HOUSING (raio mínimo, targeting bloqueado), `PAUSED`, limite de carrossel — aplicadas antes da chamada, testadas como invariante.
3. [ ] **Testes de contrato compartilhados**: `shared_examples` rodando contra fake e real; o real usa cassetes VCR gravados de conta de teste/sandbox, com `filter_sensitive_data` para tokens e `record: :none` no CI.
4. [ ] **Fake com modos de falha**: estados do container, erros por código (rate limit, token expirado 190, cota de publicação), injetáveis no teste. Respostas de erro copiadas de cassetes reais.
5. [ ] **Regravação periódica**: rotina agendada com credenciais de teste regrava os cassetes; diff no cassete = API mudou → PR para revisão humana.
6. [ ] **Ciclo de vida da versão da API**: versão em um lugar só, ADR com data de expiração, alerta antes de vencer; upgrade = regravar cassetes na nova versão.
7. [ ] **Defesa em runtime** (o contrato pode mudar sem aviso): validar resposta e falhar alto com o payload no log; consultar `publishing_limit` antes de publicar; idempotência — guardar `container_id` antes de `media_publish` para retry não postar duas vezes.
8. [ ] **LLM**: validação local da saída (JSON Schema + checagens semânticas + termos proibidos), aplicada também ao fake; cassetes por provedor (Anthropic, Gemini, OpenAI) para o caminho do `ruby_llm`; testes de contrato do uso da biblioteca para que bumps do Dependabot sejam barrados se quebrarem.

### Enquanto não há conta de teste da Meta

Situação em 2026-10-03: nenhuma conta Meta de teste/sandbox criada ainda.

Dá para fazer agora, sem credencial:

- [ ] Itens 1, 2, 4, 7 e 8 (validação local da saída do LLM) da estratégia acima.
- [ ] Fixtures provisórias a partir dos exemplos de resposta da documentação da Meta, marcadas como `fonte: documentação` — confiança menor, substituídas por cassetes gravados quando a conta existir.

Bloqueado até ter conta: itens 3 (cassetes reais) e 5 (regravação periódica).

Preparar a conta (os nomes de menu da Meta mudam; conferir na hora):

- [ ] Conta de desenvolvedor Meta e um app do tipo Business.
- [ ] **Conta Instagram profissional separada, só para teste**, ligada a uma Página do Facebook de teste. Em modo de desenvolvimento a publicação é real — não usar as contas do imóvel nem da lavanderia.
- [ ] Ad account sandbox da Marketing API (anúncios não são veiculados e não geram gasto).
- [ ] Token de longa duração guardado como secret do ambiente, nunca no repositório.

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
