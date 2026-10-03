require "rails_helper"

RSpec.describe "Fila de aprovação", type: :request do
  let(:project) { create(:project) }

  before do
    host! "app.lvh.me"
    post session_path, params: { password: ENV.fetch("ADMIN_PASSWORD", "troque-me") }
  end

  describe "aprovar" do
    it "registra quem aprovou, satisfazendo o guard da state machine" do
      post_record = create(:post, :pending_review, project:)

      post approve_project_post_path(project, post_record)

      post_record.reload
      expect(post_record.approved_by).to be_present
      expect(post_record.approved_at).to be_present
      expect(post_record).to be_approved
    end

    it "agenda quando uma data é informada" do
      post_record = create(:post, :pending_review, project:)
      quando = 2.hours.from_now

      post approve_project_post_path(project, post_record), params: { scheduled_for: quando.iso8601 }

      expect(post_record.reload).to be_scheduled
      expect(post_record.scheduled_for).to be_within(1.minute).of(quando)
    end

    it "não quebra ao tentar aprovar um post que não está em revisão" do
      post_record = create(:post, project:) # draft

      post approve_project_post_path(project, post_record)

      expect(response).to redirect_to(project_post_path(project, post_record))
      expect(post_record.reload).to be_draft
    end
  end

  describe "regenerar" do
    it "enfileira nova geração com o feedback do revisor" do
      post_record = create(:post, :pending_review, project:)

      expect {
        post regenerate_project_post_path(project, post_record), params: { feedback: "mais curto" }
      }.to have_enqueued_job(GeneratePostJob).with(post_record.id, feedback: "mais curto")
    end
  end

  describe "fila" do
    it "filtra por estado" do
      aguardando = create(:post, :pending_review, project:, caption: "Esperando revisão")
      publicado  = create(:post, project:, state: "published", caption: "Já foi ao ar")

      get project_posts_path(project, state: "pending_review")

      expect(response.body).to include("Esperando revisão")
      expect(response.body).not_to include("Já foi ao ar")
    end
  end
end
