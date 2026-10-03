#!/usr/bin/env ruby
# Stop: não deixa o agente encerrar com a árvore de trabalho vermelha.
# Roda RuboCop e testes só quando há mudança em código; o bin/ci completo
# continua sendo o portão do CI.
require "json"
require "open3"

input = JSON.parse($stdin.read) rescue {}
exit 0 if input["stop_hook_active"] # já bloqueamos uma vez; evita loop

Dir.chdir(ENV.fetch("CLAUDE_PROJECT_DIR", Dir.pwd))
changed, = Open3.capture2("git", "status", "--porcelain", "--", "app", "lib", "config", "db", "test", "Gemfile")
exit 0 if changed.strip.empty?

[["bin/rubocop"], ["bin/rails", "test"]].each do |cmd|
  out, status = Open3.capture2e(*cmd)
  next if status.success?

  warn "`#{cmd.join(' ')}` falhou. Corrija antes de encerrar:\n#{out.lines.last(40).join}"
  exit 2
end
