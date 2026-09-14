module Meta
  # Campanhas pagas. Anúncios são sempre criados PAUSADOS — ativar é uma ação
  # deliberada e separada, para ninguém descobrir que gastou dinheiro por acidente.
  class MarketingClient
    API = "https://graph.facebook.com/v21.0".freeze

    class Error < StandardError; end

    # Restrições da Special Ad Category HOUSING (anúncios de imóveis).
    HOUSING_MIN_RADIUS_KM = 25
    HOUSING_BLOCKED_TARGETING = %w[
      zips neighborhood subcity subneighborhood metro_area
      small_geo_area electoral_district genders age_min age_max
    ].freeze

    def self.build(account = nil)
      if ENV["META_FAKE"] == "true" || account.nil? || account.ad_account_id.blank?
        FakeMarketingClient.new(account)
      else
        new(account)
      end
    end

    def initialize(account)
      @account = account
    end

    def create_campaign(name:, objective:, special_ad_categories: [], status: "PAUSED")
      post("act_#{@account.ad_account_id}/campaigns",
           name: name, objective: objective, status: status,
           special_ad_categories: special_ad_categories.to_json)
    end

    def create_ad_set(campaign_id:, name:, targeting:, daily_budget_cents:,
                      optimization_goal:, billing_event:, status: "PAUSED", special_ad_category: nil)
      payload = {
        campaign_id: campaign_id, name: name, status: status,
        daily_budget: daily_budget_cents, targeting: targeting.to_json,
        optimization_goal: optimization_goal, billing_event: billing_event
      }
      # Em SAC, advantage_audience precisa ser explícito ou a criação falha.
      payload[:targeting_automation] = { advantage_audience: 0 }.to_json if special_ad_category.present?

      post("act_#{@account.ad_account_id}/adsets", payload)
    end

    def create_ad(ad_set_id:, name:, creative_id:, status: "PAUSED")
      post("act_#{@account.ad_account_id}/ads",
           adset_id: ad_set_id, name: name, creative: { creative_id: creative_id }.to_json, status: status)
    end

    def insights(object_id, fields: %w[impressions clicks spend])
      get("#{object_id}/insights", fields: fields.join(","))
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
      raise Error, "Meta Marketing API #{response.status}: #{error}"
    end
  end

  class FakeMarketingClient
    attr_reader :calls

    def initialize(account = nil)
      @account = account
      @calls = []
    end

    # Os defaults são repetidos aqui de propósito: o fake precisa registrar
    # exatamente o que o cliente real enviaria, incluindo status: PAUSED.
    def create_campaign(status: "PAUSED", **params)
      record(:create_campaign, params.merge(status:))
      { "id" => "fake_campaign_#{next_id}" }
    end

    def create_ad_set(status: "PAUSED", **params)
      record(:create_ad_set, params.merge(status:))
      { "id" => "fake_adset_#{next_id}" }
    end

    def create_ad(status: "PAUSED", **params)
      record(:create_ad, params.merge(status:))
      { "id" => "fake_ad_#{next_id}" }
    end

    def insights(object_id, fields: %w[impressions clicks spend])
      record(:insights, object_id, fields)
      { "data" => [{ "impressions" => "1200", "clicks" => "34", "spend" => "12.50" }] }
    end

    private

    def next_id = (@id = @id.to_i + 1)

    def record(method, *args)
      @calls << { method: method, args: args, at: Time.current }
    end
  end
end
