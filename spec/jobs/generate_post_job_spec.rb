require "rails_helper"

RSpec.describe GeneratePostJob do
  let(:project) { create(:project) }
  let!(:assets) { create_list(:asset, 3, project:) }

  it "deixa o post em revisão, nunca publicado" do
    post = create(:post, project:)

    described_class.perform_now(post.id)

    expect(post.reload).to be_pending_review
    expect(post).not_to be_published
  end

  it "preenche legenda e mídia a partir do resultado" do
    post = create(:post, project:)

    described_class.perform_now(post.id, context: "chove amanhã")

    post.reload
    expect(post.caption).to be_present
    expect(post.post_media.count).to eq(3)
    expect(post.post_media.map(&:position)).to eq([ 0, 1, 2 ])
  end

  it "registra uso das fotos para não repetir sempre as mesmas" do
    post = create(:post, project:)

    expect { described_class.perform_now(post.id) }
      .to change { assets.first.reload.usage_count }.by(1)
  end

  it "considera as fotos do acervo quando não há seleção explícita" do
    post = create(:post, project:)

    described_class.perform_now(post.id)

    expect(post.reload.assets).to be_present
  end
end
