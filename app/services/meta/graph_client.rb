module Meta
  # Publicação orgânica no Instagram.
  #
  # Toda chamada externa passa por aqui — nenhum job fala HTTP diretamente.
  # `.build` devolve o fake quando não há credencial, o que permite rodar a
  # esteira inteira em desenvolvimento sem publicar nada de verdade.
  class GraphClient
    API = "https://graph.facebook.com/v21.0".freeze

    class Error < StandardError; end
    class RateLimited < Error; end

    def self.build(account = nil)
      if ENV["META_FAKE"] == "true" || account.nil? || !account.connected?
        FakeGraphClient.new(account)
      else
        new(account)
      end
    end

    def initialize(account)
      @account = account
    end

    # Cota de publicação: a doc da Meta é inconsistente (50 num ponto, 100 em
    # outro), então consultamos em runtime em vez de hardcodar.
    def publishing_limit
      get("#{@account.ig_user_id}/content_publishing_limit", fields: "quota_usage,config")
    end

    def create_media_container(**params)
      post("#{@account.ig_user_id}/media", params)
    end

    def container_status(container_id)
      get(container_id, fields: "status_code,status")
    end

    def publish_container(container_id)
      post("#{@account.ig_user_id}/media_publish", creation_id: container_id)
    end

    def media_insights(ig_media_id, metrics)
      get("#{ig_media_id}/insights", metric: Array(metrics).join(","))
    end

    private

    def connection
      @connection ||= Faraday.new(url: API) do |f|
        f.request :url_encoded
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def get(path, **params)
      handle connection.get(path, params.merge(access_token: @account.access_token))
    end

    def post(path, params)
      handle connection.post(path, params.merge(access_token: @account.access_token))
    end

    def handle(response)
      return response.body if response.success?

      error = response.body.is_a?(Hash) ? response.body.dig("error", "message") : response.body
      raise RateLimited, error if response.status == 429
      raise Error, "Meta Graph API #{response.status}: #{error}"
    end
  end
end
