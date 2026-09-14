require "rails_helper"

RSpec.describe "Captura de lead", type: :request do
  let(:project) { create(:project) }
  let(:page) { create(:landing_page, :published, project:) }

  # A cadeia completa de atribuição: post → clique → visita → lead.
  it "atribui o lead à página e ao post de origem" do
    post_record = create(:post, project:)
    page.update!(post: post_record)
    link = create(:short_link, post: post_record)

    host! page.host
    post "/leads", params: {
      lead: { name: "João", phone: "11988887777" },
      consent: "1", ref: link.slug
    }

    lead = Lead.last
    expect(lead.landing_page).to eq(page)
    expect(lead.post).to eq(post_record)
    expect(lead.short_link).to eq(link)
  end

  it "recusa envio sem consentimento" do
    host! page.host
    post "/leads", params: { lead: { name: "João", phone: "11988887777" } }

    expect(Lead.count).to eq(0)
  end

  it "barra bot pelo honeypot sem criar lead" do
    host! page.host
    post "/leads", params: {
      lead: { name: "Bot", phone: "11900000000" },
      consent: "1", website: "http://spam.example"
    }

    expect(Lead.count).to eq(0)
  end
end
