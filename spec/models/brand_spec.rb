require "rails_helper"

RSpec.describe Brand do
  it "é criada junto com o projeto" do
    expect(create(:project).brand).to be_present
  end

  it "expõe cores como CSS custom properties" do
    brand = create(:project).brand
    brand.update!(primary_color: "#ff0000")

    expect(brand.css_variables["--brand-primary"]).to eq("#ff0000")
    expect(brand.css_variables_style).to include("--brand-primary: #ff0000;")
  end

  it "rejeita cor que não seja hex" do
    brand = create(:project).brand
    brand.primary_color = "vermelho"
    expect(brand).not_to be_valid
  end

  # dont_say é o que impede o LLM de escrever "oportunidade imperdível".
  it "monta instruções de prompt a partir do tom de voz" do
    brand = create(:project).brand
    brand.update!(tone_of_voice: "informal e direto",
                  do_say: [ "sol da manhã" ],
                  dont_say: [ "oportunidade única", "imperdível" ])

    instructions = brand.prompt_instructions

    expect(instructions).to include("informal e direto")
    expect(instructions).to include("sol da manhã")
    expect(instructions).to include("NUNCA use estes termos")
    expect(instructions).to include("imperdível")
  end
end
