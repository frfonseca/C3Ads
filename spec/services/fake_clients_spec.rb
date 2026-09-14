require "rails_helper"

# Os fakes são o que permite construir e testar a esteira inteira antes de
# existir qualquer credencial.
RSpec.describe "clientes em modo fake" do
  it "usa o fake do Graph quando a conta não está conectada" do
    expect(Meta::GraphClient.build(nil)).to be_a(Meta::FakeGraphClient)
  end

  it "registra as chamadas em vez de fazer HTTP" do
    client = Meta::GraphClient.build(nil)
    container = client.create_media_container(image_url: "http://exemplo/f.jpg")
    client.publish_container(container["id"])

    expect(client.calls.map { _1[:method] }).to eq(%i[create_media_container publish_container])
  end

  it "usa o fake do gerador quando não há chave de LLM" do
    expect(Content::Generator.build(nil)).to be_a(Content::FakeGenerator)
  end

  it "gera conteúdo determinístico sem chamar API" do
    project = create(:project)
    assets = create_list(:asset, 3, project:)

    result = Content::FakeGenerator.new(project).generate_post(assets:, context: "chuva amanhã")

    expect(result["caption"]).to include("chuva amanhã")
    expect(result["order"].size).to eq(3)
  end

  it "cria anúncios pausados por padrão" do
    client = Meta::MarketingClient.build(nil)
    client.create_campaign(name: "Teste", objective: "OUTCOME_TRAFFIC")

    expect(client.calls.first[:args].first[:status]).to eq("PAUSED")
  end
end
