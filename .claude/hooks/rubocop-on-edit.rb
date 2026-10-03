#!/usr/bin/env ruby
# PostToolUse (Edit|Write): corrige o estilo do arquivo Ruby editado e devolve
# ao agente o que o autocorrect não resolveu. Sensor computacional, imediato.
require "json"
require "open3"

input = JSON.parse($stdin.read) rescue exit(0)
path = input.dig("tool_input", "file_path").to_s
exit 0 unless path.end_with?(".rb", ".rake") || File.basename(path) == "Gemfile"
exit 0 unless File.exist?(path)

Dir.chdir(ENV.fetch("CLAUDE_PROJECT_DIR", Dir.pwd))
out, status = Open3.capture2e("bin/rubocop", "-a", "--format", "simple", path)
exit 0 if status.success?

warn "RuboCop encontrou problemas que o autocorrect não resolveu em #{path}:\n#{out}"
exit 2
