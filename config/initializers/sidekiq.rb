require "sidekiq"

REDIS_CONFIG = { url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6380/0") }.freeze

Sidekiq.configure_server { |c| c.redis = REDIS_CONFIG }
Sidekiq.configure_client { |c| c.redis = REDIS_CONFIG }

# Carrega os jobs recorrentes só no servidor, e só se o arquivo existir.
Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule_file = Rails.root.join("config/schedule.yml")
    if File.exist?(schedule_file) && defined?(Sidekiq::Cron::Job)
      Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_file))
    end
  end
end
