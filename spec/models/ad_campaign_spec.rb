require "rails_helper"

RSpec.describe AdCampaign do
  let(:imovel) { create(:project, :property) }
  let(:lavanderia) { create(:project, :laundry) }

  describe "Special Ad Category" do
    # A aplicabilidade de HOUSING ao Brasil não está confirmada na doc da Meta.
    # Falhamos para o lado seguro: restringir a mais não é rejeitado pela
    # plataforma; restringir a menos é.
    it "assume HOUSING em projeto de imóvel" do
      campanha = described_class.create!(project: imovel, name: "Casa Rua X")
      expect(campanha.special_ad_category).to eq("HOUSING")
    end

    it "não impõe categoria a negócio comum" do
      campanha = described_class.create!(project: lavanderia, name: "Promoção")
      expect(campanha.special_ad_category).to eq("NONE")
    end

    it "respeita escolha explícita" do
      campanha = described_class.create!(project: imovel, name: "X", special_ad_category: "NONE")
      expect(campanha.special_ad_category).to eq("NONE")
    end
  end

  describe "gasto deliberado" do
    # Ninguém deve descobrir que gastou dinheiro por acidente.
    it "não pode ir de rascunho direto a ativa" do
      campanha = described_class.create!(project: lavanderia, name: "X")
      expect { campanha.activate! }.to raise_error(AASM::InvalidTransition)
    end

    it "ativa apenas depois de criada e pausada" do
      campanha = described_class.create!(project: lavanderia, name: "X")
      campanha.mark_created!
      campanha.activate!

      expect(campanha).to be_active
      expect(campanha.activated_at).to be_present
    end
  end
end
