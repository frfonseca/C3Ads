require "rails_helper"

RSpec.describe AdTargeting do
  let(:imovel) { create(:project, :property) }
  let(:lavanderia) { create(:project, :laundry) }

  describe "restrições de imóvel" do
    # Estas não são regras nossas: são o que a Meta aceita. Validar aqui evita
    # descobrir só na hora de gastar.
    it "exige raio mínimo de 25 km" do
      alvo = described_class.new(project: imovel, radius_km: 5, latitude: -23.5, longitude: -46.6)

      expect(alvo).not_to be_valid
      expect(alvo.errors[:radius_km].join).to include("25 km")
    end

    it "proíbe segmentação por gênero" do
      alvo = described_class.new(project: imovel, genders: [ "1" ])
      expect(alvo).not_to be_valid
    end

    it "proíbe segmentação por idade" do
      alvo = described_class.new(project: imovel, age_min: 30)
      expect(alvo).not_to be_valid
    end

    it "eleva o raio ao mínimo ao montar o payload da Meta" do
      alvo = described_class.create!(project: lavanderia, radius_km: 5,
                                     latitude: -23.5, longitude: -46.6)

      payload = alvo.to_meta_hash(special_ad_category: "HOUSING")
      raio = payload.dig("geo_locations", "custom_locations", 0, "radius")

      expect(raio).to eq(25)
    end

    it "remove idade e gênero do payload em campanha de imóvel" do
      alvo = described_class.create!(project: lavanderia, age_min: 25, age_max: 45, genders: [ "1" ])

      payload = alvo.to_meta_hash(special_ad_category: "HOUSING")

      expect(payload).not_to have_key("age_min")
      expect(payload).not_to have_key("genders")
    end
  end

  describe "negócio comum" do
    it "permite segmentação fina" do
      alvo = described_class.create!(project: lavanderia, radius_km: 3, age_min: 25,
                                     latitude: -23.5, longitude: -46.6)

      payload = alvo.to_meta_hash(special_ad_category: "NONE")

      expect(payload["age_min"]).to eq(25)
      expect(payload.dig("geo_locations", "custom_locations", 0, "radius")).to eq(3)
    end
  end
end
