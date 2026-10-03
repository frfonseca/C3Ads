# ADR 0001 — Stack e integrações externas

Status: aceito

## Contexto

Projeto pequeno, de um dono, desenvolvido em grande parte por agentes de código.
Precisa rodar inteiro, com testes, em uma sessão na nuvem sem segredos e sem
acesso à internet além de gems.

## Decisão

- **Rails 8.1 + PostgreSQL 16**, com Solid Queue/Cache/Cable no próprio
  Postgres. Sem Redis: um serviço a menos para subir em dev, CI e sessões.
- **Adapters para tudo que é externo** (`app/adapters/`): um adapter por
  provedor de LLM e um para Instagram/Meta, cada um com implementação fake. Dev
  e teste usam o fake por padrão; testes que tocam HTTP usam WebMock.
- **Publicação real só com `PUBLISHING_ENABLED=true`**, nunca ligado fora de
  produção.
- **`bin/ci` (`config/ci.rb`) é o único portão**: o mesmo comando roda no laptop,
  na sessão do agente e — via jobs equivalentes — no GitHub Actions.

## Consequências

Agentes conseguem provar uma fase ponta a ponta sem credenciais. O custo é
manter os fakes fiéis aos contratos reais: cada adapter ganha contract tests
quando for criado.
