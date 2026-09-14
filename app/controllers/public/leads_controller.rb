module Public
  class LeadsController < ApplicationController
    layout "public"
    skip_forgery_protection only: :create if respond_to?(:skip_forgery_protection)

    def create
      page = LandingPage.find_by(slug: request.subdomain.to_s.downcase)
      return head :not_found if page.nil?
      return head :ok if honeypot_filled?  # bot: responde ok e ignora

      lead = page.leads.build(lead_params.merge(
        project: page.project,
        post: page.post,
        short_link: ShortLink.find_by(slug: params[:ref]),
        source: "form",
        consent_text: consent_text,
        consent_at: params[:consent].present? ? Time.current : nil
      ))

      if params[:consent].blank?
        return redirect_to("/", alert: "É preciso aceitar a política de privacidade.")
      end

      if lead.save
        redirect_to "/", notice: "Recebemos seu contato. Retornaremos em breve."
      else
        redirect_to "/", alert: lead.errors.full_messages.to_sentence
      end
    end

    private

    def lead_params = params.expect(lead: [ :name, :phone, :email, :message ])

    # Campo invisível: preenchido, é bot.
    def honeypot_filled? = params[:website].present?

    # Guardar o texto aceito, e não só um booleano: é o que prova com o que
    # a pessoa concordou, mesmo que a política mude depois.
    def consent_text
      I18n.t("privacy.consent",
             default: "Autorizo o contato sobre este anúncio e o armazenamento dos meus dados para essa finalidade.")
    end
  end
end
