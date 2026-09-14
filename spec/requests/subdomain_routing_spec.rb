require "rails_helper"

RSpec.describe "roteamento por subdomínio", type: :request do
  # O teste que justifica o painel viver em `app.`: se o cookie de sessão
  # vazasse para o domínio-pai, ele seria enviado a toda landing page pública.
  describe "isolamento do cookie de sessão" do
    it "prende o cookie ao subdomínio do painel, não ao domínio-pai" do
      domain = Rails.application.config.session_options[:domain]

      expect(domain).to eq("app.lvh.me")
      expect(domain).not_to start_with(".")
      expect(domain).not_to eq(:all)
    end
  end

  describe "slugs reservados" do
    let(:constraint) { LandingPageConstraint.new }

    it "recusa subdomínios do próprio sistema" do
      %w[app www api admin r].each do |reserved|
        request = instance_double(ActionDispatch::Request, subdomain: reserved)
        expect(constraint.matches?(request)).to be(false), "#{reserved} deveria ser reservado"
      end
    end

    it "recusa subdomínio vazio" do
      request = instance_double(ActionDispatch::Request, subdomain: "")
      expect(constraint.matches?(request)).to be(false)
    end
  end

  describe "painel" do
    it "exige autenticação" do
      host! "app.lvh.me"
      get "/"
      expect(response).to redirect_to(new_session_path)
    end
  end
end
