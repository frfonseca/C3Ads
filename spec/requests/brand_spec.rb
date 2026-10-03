require "rails_helper"

RSpec.describe "Marca", type: :request do
  before do
    host! "app.lvh.me"
    post session_path, params: { password: ENV.fetch("ADMIN_PASSWORD", "troque-me") }
  end

  it "aplica cores como CSS custom properties na prévia" do
    project = create(:project)
    project.brand.update!(primary_color: "#ff5500")

    get edit_project_brand_path(project)

    expect(response.body).to include("--brand-primary: #ff5500;")
  end

  it "aceita listas de termos digitadas linha a linha" do
    project = create(:project)

    patch project_brand_path(project), params: {
      brand: { dont_say_text: "oportunidade única\nimperdível\n" }
    }

    expect(project.brand.reload.dont_say).to eq([ "oportunidade única", "imperdível" ])
  end
end
