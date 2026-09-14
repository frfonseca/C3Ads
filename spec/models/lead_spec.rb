require "rails_helper"

RSpec.describe Lead do
  let(:project) { create(:project) }

  it "exige ao menos uma forma de contato" do
    expect(build(:lead, project:, phone: nil, email: nil)).not_to be_valid
  end

  describe "LGPD" do
    it "anonimiza apagando a PII e mantendo a estatística" do
      lead = create(:lead, project:, name: "Maria", phone: "11999990000", email: "m@x.com")

      lead.anonymize!

      lead.reload
      expect(lead.name).to be_nil
      expect(lead.phone).to be_nil
      expect(lead.email).to be_nil
      expect(lead.anonymized_at).to be_present
      # A linha continua existindo — a contagem de leads por post sobrevive.
      expect(Lead.where(id: lead.id)).to exist
    end

    it "guarda o texto do consentimento, não só um booleano" do
      lead = create(:lead, project:, consent_text: "Autorizo o contato sobre este anúncio.")
      expect(lead.consent_text).to include("Autorizo")
      expect(lead.consent_at).to be_present
    end

    it "seleciona leads parados há mais de 12 meses" do
      antigo = create(:lead, project:)
      antigo.update_column(:updated_at, 13.months.ago)
      create(:lead, project:)

      expect(Lead.stale).to contain_exactly(antigo)
    end

    it "o job de retenção anonimiza os antigos" do
      antigo = create(:lead, project:)
      antigo.update_column(:updated_at, 13.months.ago)

      AnonymizeStaleLeadsJob.perform_now

      expect(antigo.reload).to be_anonymized
    end
  end
end
