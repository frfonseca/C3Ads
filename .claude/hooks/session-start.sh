#!/bin/bash
# Prepara o ambiente das sessões na nuvem (Claude Code on the web):
# Postgres no ar, gems instaladas, banco criado. Localmente não faz nada.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

if ! pg_isready -q 2>/dev/null; then
  service postgresql start >/dev/null 2>&1 || pg_ctlcluster 16 main start
  for _ in $(seq 1 20); do pg_isready -q && break; sleep 0.5; done
fi

if ! su postgres -c "psql -tAc \"select 1 from pg_roles where rolname='$(whoami)'\"" | grep -q 1; then
  su postgres -c "createuser -s $(whoami)"
fi

bundle install --quiet
bin/rails db:prepare >/dev/null
