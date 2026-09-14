RubyLLM.configure do |config|
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.gemini_api_key    = ENV["GEMINI_API_KEY"]
  config.openai_api_key    = ENV["OPENAI_API_KEY"]

  # Não usamos a API legada acts_as_chat; o projeto fala com RubyLLM.chat direto.
  config.use_new_acts_as = true if config.respond_to?(:use_new_acts_as=)
end
