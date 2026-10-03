require "sidekiq"

REDIS_CONFIG = { url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6380/0") }.freeze

Sidekiq.configure_server { |c| c.redis = REDIS_CONFIG }
Sidekiq.configure_client { |c| c.redis = REDIS_CONFIG }
