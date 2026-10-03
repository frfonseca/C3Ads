require "rails_helper"

# A invariante central do projeto: nada chega a `published` sem aprovação
# humana registrada. Estes testes existem para provar que nenhum caminho de
# código — job, console ou gatilho automático — consegue contorná-la.
RSpec.describe Post do
  describe "aprovação obrigatória" do
    it "não permite aprovar sem registrar quem aprovou" do
      post = create(:post, :pending_review)

      expect { post.approve! }.to raise_error(AASM::InvalidTransition)
      expect(post.reload).not_to be_approved
    end

    it "aprova quando quem aprovou está registrado" do
      post = create(:post, :pending_review)

      post.approve_by!("frederico")

      expect(post).to be_approved
      expect(post.approved_by).to eq("frederico")
      expect(post.approved_at).to be_present
    end

    it "recusa aprovador em branco" do
      post = create(:post, :pending_review)

      expect { post.approve_by!("") }.to raise_error(ArgumentError)
      expect(post.reload).to be_pending_review
    end

    it "não agenda um post aprovado se a aprovação for apagada" do
      post = create(:post, :approved)
      post.update_columns(approved_at: nil, approved_by: nil)

      expect { post.schedule! }.to raise_error(AASM::InvalidTransition)
    end

    it "não inicia publicação sem aprovação registrada" do
      post = create(:post, :scheduled)
      post.update_columns(approved_at: nil, approved_by: nil)

      expect { post.start_publishing! }.to raise_error(AASM::InvalidTransition)
    end

    # O teste que resume a fase: não existe atalho de draft a published.
    it "não tem nenhum caminho de draft a published sem passar por aprovação" do
      post = create(:post)

      expect(post).to be_draft
      expect { post.start_publishing! }.to raise_error(AASM::InvalidTransition)
      expect { post.mark_published! }.to raise_error(AASM::InvalidTransition)
      expect { post.schedule! }.to raise_error(AASM::InvalidTransition)
      expect(post.reload).to be_draft
    end

    it "percorre o caminho feliz completo" do
      post = create(:post, :pending_review)

      post.approve_by!("frederico", scheduled_for: 2.hours.from_now)
      post.schedule!
      post.start_publishing!
      post.mark_published!

      expect(post).to be_published
    end
  end

  describe "limite do carrossel" do
    it "rejeita mais de 10 itens" do
      post = build(:post, media_type: "carousel")
      11.times { |i| post.post_media.build(asset: create(:asset), position: i) }

      expect(post).not_to be_valid
      expect(post.errors[:base].join).to match(/10 itens/)
    end
  end

  describe "reprovação" do
    it "permite rejeitar um post em revisão" do
      post = create(:post, :pending_review)
      post.reject!
      expect(post).to be_rejected
    end
  end
end
