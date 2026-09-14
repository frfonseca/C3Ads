require "rails_helper"

RSpec.describe Notifier::Telegram do
  it "não está configurado sem token" do
    expect(described_class.new(token: nil, chat_id: nil)).not_to be_configured
  end

  it "registra em log em vez de falhar quando não há token" do
    alert = SystemAlert.create!(kind: "teste", message: "mensagem", severity: "warning")
    expect(described_class.new(token: nil, chat_id: nil).deliver(alert)).to be(false)
  end

  # Alerta é conveniência; o banco é a fonte de verdade. Uma falha de rede no
  # Telegram não pode derrubar o job que originou o alerta.
  it "engole erro de rede sem levantar exceção" do
    alert = SystemAlert.create!(kind: "teste", message: "mensagem", severity: "critical")
    notifier = described_class.new(token: "t", chat_id: "c")
    allow(notifier).to receive(:connection).and_raise(Faraday::ConnectionFailed, "sem rede")

    expect { notifier.deliver(alert) }.not_to raise_error
  end
end
