module Meta
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
      { "data" => [ { "impressions" => "1200", "clicks" => "34", "spend" => "12.50" } ] }
    end

    private

    def next_id = (@id = @id.to_i + 1)

    def record(method, *args)
      @calls << { method: method, args: args, at: Time.current }
    end
  end
end
