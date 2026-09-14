require "rails_helper"

RSpec.describe Media::Resizer do
  it "devolve o anexo quando não é imagem" do
    non_image = double(content_type: "application/pdf", respond_to?: true)
    allow(non_image).to receive(:respond_to?).with(:variant).and_return(true)
    allow(non_image).to receive(:try).with(:content_type).and_return("application/pdf")

    expect(described_class.call(non_image)).to eq(non_image)
  end

  it "não derruba a geração se o redimensionamento falhar" do
    asset = create(:asset)
    allow(asset.file).to receive(:variant).and_raise(StandardError, "libvips indisponível")

    expect { described_class.call(asset.file) }.not_to raise_error
  end

  it "usa 2000px como limite, o teto seguro para lotes de 20 fotos" do
    expect(described_class::LONG_EDGE).to eq(2000)
  end
end
