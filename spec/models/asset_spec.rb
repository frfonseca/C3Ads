require "rails_helper"

RSpec.describe Asset do
  it "nasce privado por padrão" do
    expect(create(:asset).visibility).to eq("private")
  end

  describe ".publicly_visible" do
    # A regra que impede matrícula de imóvel de vazar para uma landing page
    # indexável. É o escopo que os templates públicos devem usar.
    it "expõe apenas assets marcados como públicos" do
      project = create(:project)
      publico  = create(:asset, :public_asset, project:, title: "Fachada")
      privado  = create(:asset, project:, title: "Matrícula", kind: "document")
      interno  = create(:asset, project:, visibility: "internal")

      visiveis = project.assets.publicly_visible

      expect(visiveis).to include(publico)
      expect(visiveis).not_to include(privado, interno)
    end
  end

  it "registra uso para evitar repetir a mesma foto" do
    asset = create(:asset)
    expect { asset.record_use! }.to change { asset.reload.usage_count }.by(1)
    expect(asset.last_used_at).to be_present
  end

  it "ordena por menos usado recentemente" do
    project = create(:project)
    nunca = create(:asset, project:)
    usado = create(:asset, project:)
    usado.record_use!

    expect(project.assets.least_recently_used.first).to eq(nunca)
  end
end
