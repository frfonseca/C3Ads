require "rails_helper"

RSpec.describe Trigger do
  let(:project) { create(:project) }

  it "não inclui gatilhos manuais na avaliação automática" do
    create(:trigger, project:, kind: "manual")
    agendado = create(:trigger, project:, kind: "schedule")

    expect(described_class.automatic).to contain_exactly(agendado)
  end

  describe "debounce" do
    # Sem isso, uma semana de chuva geraria sete posts iguais.
    it "fica em cooldown após disparar" do
      trigger = create(:trigger, project:, cooldown_hours: 24, last_fired_at: 2.hours.ago)
      expect(trigger).to be_in_cooldown
    end

    it "sai do cooldown depois do prazo" do
      trigger = create(:trigger, project:, cooldown_hours: 24, last_fired_at: 25.hours.ago)
      expect(trigger).not_to be_in_cooldown
    end

    it "nunca esteve em cooldown se nunca disparou" do
      expect(create(:trigger, project:, last_fired_at: nil)).not_to be_in_cooldown
    end
  end
end
