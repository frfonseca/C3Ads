require "rails_helper"

RSpec.describe GenerationCost do
  let(:project) { create(:project, monthly_cost_limit_usd: 10) }

  it "soma o custo do mês corrente" do
    create(:generation_cost, project:, usd: 1.5)
    create(:generation_cost, project:, usd: 2.25)

    expect(described_class.month_total(project)).to eq(3.75)
  end

  it "ignora custos de meses anteriores" do
    antigo = create(:generation_cost, project:, usd: 100)
    antigo.update_column(:created_at, 2.months.ago)

    expect(described_class.month_total(project)).to eq(0)
  end

  it "detecta limite atingido" do
    create(:generation_cost, project:, usd: 10)
    expect(described_class.limit_reached?(project)).to be(true)
  end

  it "não limita projeto sem teto definido" do
    sem_limite = create(:project, monthly_cost_limit_usd: nil)
    create(:generation_cost, project: sem_limite, usd: 999)

    expect(described_class.limit_reached?(sem_limite)).to be(false)
  end

  it "bloqueia geração quando o limite é atingido" do
    create(:generation_cost, project:, usd: 10)
    post = create(:post, project:)

    GeneratePostJob.perform_now(post.id)

    expect(post.reload).to be_draft
    expect(SystemAlert.find_by(kind: "cost_limit_reached")).to be_present
  end
end
