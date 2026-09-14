require "rails_helper"

RSpec.describe EvaluateTriggersJob do
  let(:project) { create(:project) }

  def gatilho_de_chuva(**attrs)
    create(:trigger, project:, kind: "weather",
                     condition: { "latitude" => -23.5, "longitude" => -46.6,
                                  "metric" => "precipitation_probability",
                                  "op" => ">", "value" => 60, "horizon_hours" => 24 },
                     **attrs)
  end

  def prever_chuva(probabilidade)
    allow_any_instance_of(Triggers::Weather).to receive(:peak_value).and_return(probabilidade)
  end

  it "cria post que termina em revisão, nunca publicado" do
    gatilho_de_chuva
    prever_chuva(85)

    perform_enqueued_jobs { described_class.perform_now }

    post = Post.last
    expect(post).to be_pending_review
    expect(post).not_to be_published
  end

  it "não dispara quando a condição não é atendida" do
    gatilho_de_chuva
    prever_chuva(20)

    expect { described_class.perform_now }.not_to change(Post, :count)
    expect(TriggerEvent.last.fired).to be(false)
  end

  # O teste que impede sete posts iguais numa semana de chuva.
  it "respeita o cooldown mesmo com a condição atendida" do
    gatilho_de_chuva(cooldown_hours: 24, last_fired_at: 2.hours.ago)
    prever_chuva(90)

    expect { described_class.perform_now }.not_to change(Post, :count)
    expect(TriggerEvent.last.reason).to eq("em cooldown")
  end

  it "passa o contexto do clima para a geração" do
    gatilho_de_chuva
    prever_chuva(80)

    described_class.perform_now

    enfileirado = ActiveJob::Base.queue_adapter.enqueued_jobs.find { _1["job_class"] == "GeneratePostJob" }
    contexto = enfileirado["arguments"].last["context"]
    expect(contexto).to include("80%")
    expect(contexto).to include("chuva")
  end

  it "registra cada avaliação, tenha disparado ou não" do
    gatilho_de_chuva
    prever_chuva(10)

    described_class.perform_now

    expect(TriggerEvent.count).to eq(1)
    expect(TriggerEvent.last.evaluated_at).to be_present
  end

  it "um gatilho com erro não impede os outros de rodar" do
    quebrado = gatilho_de_chuva
    allow_any_instance_of(Triggers::Weather).to receive(:fired?).and_raise("API fora do ar")

    expect { described_class.perform_now }.not_to raise_error
    expect(quebrado.trigger_events.last.reason).to include("erro")
  end

  it "alerta que há post esperando aprovação" do
    gatilho_de_chuva
    prever_chuva(75)

    described_class.perform_now

    expect(SystemAlert.find_by(kind: "trigger_fired")).to be_present
  end
end
