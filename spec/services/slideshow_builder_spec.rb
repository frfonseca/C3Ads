require "rails_helper"

RSpec.describe Video::SlideshowBuilder do
  let(:project) { create(:project) }

  def post_com_fotos(n = 3, highlights: [])
    post = create(:post, project:, generation_meta: { "highlights" => highlights })
    n.times { |i| post.post_media.create!(asset: create(:asset, project:), position: i) }
    post
  end

  describe "spec" do
    it "usa 9:16, o formato do Reels" do
      spec = described_class.new(post_com_fotos).spec
      expect(spec["width"]).to eq(1080)
      expect(spec["height"]).to eq(1920)
    end

    it "monta um slide por foto, na ordem aprovada" do
      spec = described_class.new(post_com_fotos(4)).spec
      expect(spec["slides"].size).to eq(4)
      expect(spec["slides"].map { _1["position"] }).to eq([ 0, 1, 2, 3 ])
    end

    # O slideshow herda a curadoria do LLM sem trabalho extra.
    it "aproveita os destaques identificados pelo LLM como legendas" do
      spec = described_class.new(post_com_fotos(2, highlights: [ "Sol da manhã", "Garagem coberta" ])).spec
      expect(spec["slides"].map { _1["caption"] }).to eq([ "Sol da manhã", "Garagem coberta" ])
    end

    # Música comercial em anúncio é risco de direito autoral e derrubada do post.
    it "não inclui áudio por padrão" do
      expect(described_class.new(post_com_fotos).spec["audio"]).to be_nil
    end

    it "respeita a duração mínima do Reels mesmo com uma foto só" do
      expect(described_class.new(post_com_fotos(1)).spec["duration"]).to be >= 3
    end

    it "limita a duração máxima" do
      expect(described_class.new(post_com_fotos(60)).spec["duration"]).to be <= 90
    end

    it "carrega as cores da marca" do
      project.brand.update!(primary_color: "#112233")
      expect(described_class.new(post_com_fotos).spec.dig("brand", "primary")).to eq("#112233")
    end
  end

  describe "sem ffmpeg" do
    it "levanta erro explícito em vez de falhar de forma obscura" do
      allow(described_class).to receive(:available?).and_return(false)

      expect { described_class.new(post_com_fotos).render!("/tmp/x.mp4") }
        .to raise_error(described_class::FfmpegMissing)
    end
  end
end
