require "rails_helper"

RSpec.describe SyncPostMetricsJob do
  let(:account) { create(:account) }
  let(:project) { create(:project, account:) }

  def published_post(media_type: "carousel", published_at: 2.days.ago)
    create(:post, project:, account:, media_type:, state: "published",
                  approved_at: 3.days.ago, approved_by: "frederico",
                  ig_media_id: "media_#{SecureRandom.hex(4)}", published_at:)
  end

  before { allow(Meta::GraphClient).to receive(:build).and_return(Meta::FakeGraphClient.new(account)) }

  it "coleta métricas dos posts publicados" do
    post = published_post

    described_class.perform_now

    expect(post.post_metrics.count).to eq(1)
    expect(post.post_metrics.last.reach).to be_present
  end

  # Os números mudam nas primeiras 48h — sobrescrever perderia a evolução.
  it "guarda histórico em vez de sobrescrever" do
    post = published_post

    described_class.perform_now(post.id)
    travel_to(2.hours.from_now) { described_class.perform_now(post.id) }

    expect(post.post_metrics.count).to eq(2)
  end

  it "não duplica coleta dentro da mesma hora" do
    post = published_post

    described_class.perform_now(post.id)
    described_class.perform_now(post.id)

    expect(post.post_metrics.count).to eq(1)
  end

  it "ignora posts antigos demais" do
    published_post(published_at: 60.days.ago)

    described_class.perform_now

    expect(PostMetric.count).to eq(0)
  end

  it "usa métricas próprias de Reels" do
    post = published_post(media_type: "reel")
    fake = Meta::FakeGraphClient.new(account)
    allow(Meta::GraphClient).to receive(:build).and_return(fake)

    described_class.perform_now(post.id)

    metrics_pedidas = fake.calls.find { |c| c[:method] == :media_insights }[:args].last
    expect(metrics_pedidas).to include("plays")
  end
end
