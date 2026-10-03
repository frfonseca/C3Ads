require "rails_helper"
require "zip"

RSpec.describe Posts::Exporter do
  let(:project) { create(:project) }

  # O teste prático da saída de emergência: o zip precisa bastar por si só
  # para alguém publicar pelo celular, sem consultar o sistema.
  it "entrega fotos numeradas na ordem aprovada e a legenda" do
    post = create(:post, :approved, project:, caption: "Casa com sol da manhã",
                                    hashtags: %w[casa bairro])
    3.times do |i|
      post.post_media.create!(asset: create(:asset, project:, title: "foto#{i}"), position: i)
    end

    zip = described_class.new(post).call
    entries = []
    Zip::File.open_buffer(zip.string) { |z| entries = z.map(&:name) }

    expect(entries).to include("legenda.txt")
    expect(entries.grep(/^01-/).size).to eq(1)
    expect(entries.grep(/^03-/).size).to eq(1)
  end

  it "inclui legenda e hashtags prontas para colar" do
    post = create(:post, :approved, project:, caption: "Legenda pronta", hashtags: %w[um dois])
    post.post_media.create!(asset: create(:asset, project:), position: 0)

    zip = described_class.new(post).call
    conteudo = nil
    Zip::File.open_buffer(zip.string) { |z| conteudo = z.get_entry("legenda.txt").get_input_stream.read }

    expect(conteudo).to include("Legenda pronta")
    expect(conteudo).to include("#um #dois")
  end
end
