require "rails_helper"

RSpec.describe RenderVideoJob do
  let(:project) { create(:project) }

  def render_pendente
    post = create(:post, project:)
    2.times { |i| post.post_media.create!(asset: create(:asset, project:), position: i) }
    VideoRender.create!(post:)
  end

  it "roda na fila de vídeo, isolada da publicação" do
    expect(described_class.new.queue_name).to eq("video")
  end

  it "guarda a spec mesmo quando não pode renderizar" do
    allow(Video::SlideshowBuilder).to receive(:available?).and_return(false)
    render = render_pendente

    described_class.perform_now(render.id)

    render.reload
    expect(render.spec["slides"].size).to eq(2)
    expect(render.duration_seconds).to be_positive
  end

  # Sem ffmpeg o sistema segue utilizável: o post continua como carrossel.
  it "falha de forma controlada sem ffmpeg, sem derrubar o post" do
    allow(Video::SlideshowBuilder).to receive(:available?).and_return(false)
    render = render_pendente

    expect { described_class.perform_now(render.id) }.not_to raise_error

    expect(render.reload.state).to eq("failed")
    expect(render.error_message).to include("ffmpeg")
    expect(render.post.reload).to be_draft
  end
end
