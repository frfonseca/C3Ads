require "rails_helper"

RSpec.describe "Link curto", type: :request do
  let(:project) { create(:project, whatsapp_number: "+55 11 98888-7777") }

  def link_para(destino)
    create(:short_link, destination: destino, post: create(:post, project:))
  end

  # O teste que mais importa não é o caminho feliz: é o degradado. A analítica
  # nunca pode quebrar o caminho do interessado.
  it "redireciona mesmo se o registro do clique falhar" do
    link = link_para(create(:destination))
    allow(LinkClick).to receive(:create!).and_raise(StandardError, "banco fora")

    get "/r/#{link.slug}"

    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("wa.me")
  end

  it "registra o clique e incrementa o contador" do
    link = link_para(create(:destination))

    expect { get "/r/#{link.slug}" }.to change { link.reload.click_count }.by(1)
    expect(link.link_clicks.count).to eq(1)
  end

  it "não conta preview do Instagram ou WhatsApp como visita" do
    link = link_para(create(:destination))

    get "/r/#{link.slug}", headers: { "HTTP_USER_AGENT" => "WhatsApp/2.23 facebookexternalhit/1.1" }

    expect(link.reload.click_count).to eq(0)
  end

  it "nunca guarda IP em claro" do
    link = link_para(create(:destination))

    get "/r/#{link.slug}", env: { "REMOTE_ADDR" => "203.0.113.7" }

    click = link.link_clicks.last
    expect(click.ip_hash).to be_present
    expect(click.ip_hash).not_to include("203.0.113")
  end

  # Open redirect transformaria este domínio em trampolim para phishing.
  it "recusa destino fora da lista permitida e cai no fallback" do
    destino = create(:destination, kind: "landing")
    allow_any_instance_of(Destination).to receive(:url).and_return("https://site-malicioso.example/phish")
    link = link_para(destino)

    get "/r/#{link.slug}"

    expect(response.location).not_to include("site-malicioso")
  end

  it "aceita destino de WhatsApp" do
    link = link_para(create(:destination))

    get "/r/#{link.slug}"

    expect(response.location).to include("wa.me")
  end

  it "devolve 404 amigável para slug inexistente" do
    get "/r/naoexiste"
    expect(response).to have_http_status(:not_found)
  end

  it "monta URL de WhatsApp com mensagem pré-preenchida" do
    destino = create(:destination, prefilled_message: "Vi o anúncio da casa")
    link = link_para(destino)

    get "/r/#{link.slug}"

    expect(response.location).to include("text=Vi+o+an%C3%BAncio") .or include("text=Vi%20o%20an")
  end
end
