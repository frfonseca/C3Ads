require "rails_helper"

RSpec.describe PublishPostJob do
  let(:account) { create(:account) }
  let(:project) { create(:project, account:) }

  def scheduled_post(media_type: "carousel", items: 2)
    post = create(:post, :scheduled, project:, account:, media_type:)
    items.times { |i| post.post_media.create!(asset: create(:asset, project:), position: i) }
    post
  end

  describe "idempotência" do
    # O cenário real: timeout de rede, Sidekiq repete o job, e o post não pode
    # aparecer duas vezes no perfil.
    it "não republica um post que já tem ig_media_id" do
      post = scheduled_post
      post.update_columns(ig_media_id: "ja_publicado", state: "published")
      fake = Meta::FakeGraphClient.new(account)
      allow(Meta::GraphClient).to receive(:build).and_return(fake)

      described_class.perform_now(post.id)

      expect(fake.calls).to be_empty
    end

    it "reutiliza o container existente em vez de criar outro" do
      post = scheduled_post
      post.update_columns(ig_container_id: "container_ja_criado")
      fake = Meta::FakeGraphClient.new(account)
      allow(Meta::GraphClient).to receive(:build).and_return(fake)

      described_class.perform_now(post.id)

      criados = fake.calls.count { |c| c[:method] == :create_media_container }
      expect(criados).to eq(0)
      expect(fake.calls.find { |c| c[:method] == :publish_container }[:args]).to eq([ "container_ja_criado" ])
    end

    it "executar duas vezes gera uma única publicação" do
      post = scheduled_post
      fake = Meta::FakeGraphClient.new(account)
      allow(Meta::GraphClient).to receive(:build).and_return(fake)

      described_class.perform_now(post.id)
      described_class.perform_now(post.id)

      publicacoes = fake.calls.count { |c| c[:method] == :publish_container }
      expect(publicacoes).to eq(1)
    end
  end

  describe "aprovação" do
    it "recusa publicar sem aprovação registrada" do
      post = scheduled_post
      post.update_columns(approved_at: nil, approved_by: nil)
      fake = Meta::FakeGraphClient.new(account)
      allow(Meta::GraphClient).to receive(:build).and_return(fake)

      described_class.perform_now(post.id)

      expect(fake.calls).to be_empty
      expect(post.reload).not_to be_published
    end
  end

  describe "caminho feliz" do
    it "publica e guarda o ig_media_id" do
      post = scheduled_post
      allow(Meta::GraphClient).to receive(:build).and_return(Meta::FakeGraphClient.new(account))

      described_class.perform_now(post.id)

      post.reload
      expect(post).to be_published
      expect(post.ig_media_id).to be_present
      expect(post.published_at).to be_present
    end

    it "registra cada passo em PublishAttempt" do
      post = scheduled_post
      allow(Meta::GraphClient).to receive(:build).and_return(Meta::FakeGraphClient.new(account))

      described_class.perform_now(post.id)

      expect(post.publish_attempts.pluck(:step)).to include("container", "status", "publish")
    end
  end

  describe "cota" do
    it "reagenda em vez de falhar quando a cota está estourada" do
      post = scheduled_post
      fake = Meta::FakeGraphClient.new(account)
      allow(fake).to receive(:publishing_limit)
        .and_return({ "data" => [ { "quota_usage" => 100, "config" => { "quota_total" => 100 } } ] })
      allow(Meta::GraphClient).to receive(:build).and_return(fake)

      expect { described_class.perform_now(post.id) }
        .to have_enqueued_job(described_class).with(post.id)
      expect(post.reload.state).to eq("scheduled")
    end
  end
end
