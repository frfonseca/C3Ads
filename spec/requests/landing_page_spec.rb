require "rails_helper"

RSpec.describe "Landing pages", type: :request do
  let(:project) { create(:project, :property) }

  describe "vazamento de asset privado" do
    # O teste com maior custo real do sistema: uma matrícula de imóvel exposta
    # numa página indexável pelo Google.
    it "nunca expõe assets privados na página pública" do
      page = create(:landing_page, :published, :property, project:)
      publico  = create(:asset, :public_asset, project:, title: "Fachada")
      privado  = create(:asset, :document, project:, title: "Matricula-12345")
      page.landing_media.create!(asset: publico, position: 0)
      page.landing_media.create!(asset: privado, position: 1)

      host! page.host
      get "/"

      expect(response.body).to include("Fachada")
      expect(response.body).not_to include("Matricula-12345")
    end

    it "o escopo da página só devolve assets públicos" do
      page = create(:landing_page, :published, project:)
      page.landing_media.create!(asset: create(:asset, :public_asset, project:), position: 0)
      page.landing_media.create!(asset: create(:asset, project:), position: 1)

      expect(page.public_assets.count).to eq(1)
    end
  end

  describe "expiração" do
    it "mostra aviso de oferta encerrada, não 404" do
      page = create(:landing_page, :expired, project:)

      host! page.host
      get "/"

      expect(response).to have_http_status(:gone)
      expect(response.body).to include("terminou")
    end
  end

  describe "slug" do
    it "recusa slug reservado pelo sistema" do
      page = build(:landing_page, slug: "app")
      expect(page).not_to be_valid
    end

    it "normaliza o slug para um hostname válido" do
      page = build(:landing_page, slug: "Casa da Rua X!")
      page.valid?
      expect(page.slug).to eq("casa-da-rua-x")
    end

    it "recusa slug longo demais para um rótulo de DNS" do
      expect(build(:landing_page, slug: "a" * 64)).not_to be_valid
    end

    it "guarda o slug antigo ao renomear, para não quebrar o que já circulou" do
      page = create(:landing_page, :published, project:, slug: "casa-antiga")
      page.update!(slug: "casa-nova")

      expect(page.reload.previous_slugs).to include("casa-antiga")
    end
  end

  describe "OpenGraph" do
    it "inclui imagem e título para o preview do WhatsApp" do
      page = create(:landing_page, :published, project:, title: "Casa na Rua X")
      page.landing_media.create!(asset: create(:asset, :public_asset, project:), position: 0)

      host! page.host
      get "/"

      expect(response.body).to include('property="og:title"')
      expect(response.body).to include("Casa na Rua X")
      expect(response.body).to include('property="og:image"')
    end
  end
end
