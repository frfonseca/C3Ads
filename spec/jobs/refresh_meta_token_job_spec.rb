require "rails_helper"

RSpec.describe RefreshMetaTokenJob do
  # O teste que evita a falha silenciosa mais provável do sistema.
  it "alerta quando o token está perto de vencer" do
    create(:account, name: "Lavanderia", token_expires_at: 5.days.from_now)

    described_class.perform_now

    alerta = SystemAlert.find_by(kind: "meta_token_expiring")
    expect(alerta).to be_present
    expect(alerta.severity).to eq("critical")
    expect(alerta.message).to include("Lavanderia")
  end

  it "ignora contas com token longe do vencimento" do
    create(:account, token_expires_at: 50.days.from_now)

    described_class.perform_now

    expect(SystemAlert.where(kind: "meta_token_expiring")).to be_empty
  end

  it "alerta com instrução clara quando a renovação falha" do
    create(:account, name: "Casa", token_expires_at: 3.days.from_now)
    stub_const("ENV", ENV.to_hash.merge("META_APP_ID" => "1", "META_APP_SECRET" => "s"))
    allow_any_instance_of(described_class).to receive(:exchange).and_raise("token inválido")

    described_class.perform_now

    alerta = SystemAlert.find_by(kind: "meta_token_refresh_failed")
    expect(alerta.message).to include("refazer a autorização")
  end
end
