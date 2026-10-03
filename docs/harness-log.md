# Harness log

Cada vez que um agente (ou humano) erra de um jeito que pode se repetir, a
correção inclui o harness. Uma linha por caso: o erro e o guide ou sensor que
passou a evitá-lo.

| Data | Erro observado | Mudança no harness |
|---|---|---|
| 2026-10-03 | `.gitignore` original não ignorava `config/master.key` | Padrões `/config/*.key` e `.env*` no `.gitignore` |
