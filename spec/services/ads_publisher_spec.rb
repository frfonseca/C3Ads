require "rails_helper"

RSpec.describe Ads::Publisher do
  let(:account) { create(:account, ad_account_id: "act_123") }
  let(:project) { create(:project, :property, account:) }

  it "cria campanha e conjunto sempre pausados" do
    campanha = AdCampaign.create!(project:, name: "Casa Rua X", daily_budget_cents: 1000)
    fake = Meta::FakeMarketingClient.new(account)
    allow(Meta::MarketingClient).to receive(:build).and_return(fake)

    described_class.new(campanha).call

    fake.calls.each do |call|
      expect(call[:args].first[:status]).to eq("PAUSED")
    end
    expect(campanha.reload.state).to eq("created_paused")
  end

  it "envia a categoria HOUSING no nível da campanha" do
    campanha = AdCampaign.create!(project:, name: "Casa", daily_budget_cents: 1000)
    fake = Meta::FakeMarketingClient.new(account)
    allow(Meta::MarketingClient).to receive(:build).and_return(fake)

    described_class.new(campanha).call

    criacao = fake.calls.find { _1[:method] == :create_campaign }
    expect(criacao[:args].first[:special_ad_categories]).to eq([ "HOUSING" ])
  end

  # Múltiplas fontes indicam que omitir advantage_audience em SAC faz a
  # criação falhar. Não está confirmado na doc oficial, mas setar custa nada.
  it "define advantage_audience explicitamente em campanha de imóvel" do
    campanha = AdCampaign.create!(project:, name: "Casa", daily_budget_cents: 1000)
    fake = Meta::FakeMarketingClient.new(account)
    allow(Meta::MarketingClient).to receive(:build).and_return(fake)

    described_class.new(campanha).call

    conjunto = fake.calls.find { _1[:method] == :create_ad_set }
    expect(conjunto[:args].first[:special_ad_category]).to eq("HOUSING")
  end

  it "alerta e marca como falha quando a Meta recusa" do
    campanha = AdCampaign.create!(project:, name: "Casa", daily_budget_cents: 1000)
    fake = Meta::FakeMarketingClient.new(account)
    allow(fake).to receive(:create_campaign).and_raise(Meta::MarketingClient::Error, "orçamento inválido")
    allow(Meta::MarketingClient).to receive(:build).and_return(fake)

    expect(described_class.new(campanha).call).to be(false)
    expect(campanha.reload.state).to eq("failed")
    expect(SystemAlert.find_by(kind: "ad_creation_failed")).to be_present
  end
end
