module Ads
  # Cria a hierarquia Campaign → AdSet → Ad na Meta, sempre PAUSADA.
  #
  # Ativar é uma ação deliberada e separada: ninguém deve descobrir que gastou
  # dinheiro por acidente.
  class Publisher
    def initialize(campaign)
      @campaign = campaign
      @client = Meta::MarketingClient.build(campaign.project.account)
    end

    def call
      return false unless @campaign.may_mark_created?

      meta_campaign = create_campaign
      ad_set = create_ad_set(meta_campaign["id"])

      @campaign.update!(meta_campaign_id: meta_campaign["id"], meta_ad_set_id: ad_set["id"])
      @campaign.mark_created!
      true
    rescue StandardError => e
      @campaign.mark_failed! if @campaign.may_mark_failed?
      SystemAlert.raise_alert(
        kind: "ad_creation_failed", severity: "warning",
        message: "Falha ao criar a campanha #{@campaign.name}: #{e.message}",
        context: { campaign_id: @campaign.id }
      )
      false
    end

    private

    def create_campaign
      categories = @campaign.special_ad_category == "NONE" ? [] : [ @campaign.special_ad_category ]
      @client.create_campaign(name: @campaign.name, objective: @campaign.objective,
                              special_ad_categories: categories, status: "PAUSED")
    end

    def create_ad_set(campaign_id)
      targeting = @campaign.ad_targeting&.to_meta_hash(special_ad_category: @campaign.special_ad_category) ||
                  { "geo_locations" => { "countries" => [ "BR" ] } }

      @client.create_ad_set(
        campaign_id:, name: "#{@campaign.name} — conjunto",
        targeting:, daily_budget_cents: @campaign.daily_budget_cents,
        optimization_goal: "LINK_CLICKS", billing_event: "IMPRESSIONS",
        status: "PAUSED",
        # Em SAC, advantage_audience precisa ser explícito ou a criação falha.
        special_ad_category: @campaign.housing? ? @campaign.special_ad_category : nil
      )
    end
  end
end
