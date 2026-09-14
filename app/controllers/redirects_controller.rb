# Link curto: registra o clique e redireciona.
#
# Regra inegociável: se o registro falhar, redireciona mesmo assim. A analítica
# nunca pode quebrar o caminho do interessado.
class RedirectsController < ApplicationController
  allow_browser versions: :modern, block: -> { } if respond_to?(:allow_browser)

  def show
    link = ShortLink.find_by(slug: params[:slug])
    return render plain: "Link não encontrado", status: :not_found if link.nil?

    track(link)
    redirect_to safe_target(link), allow_other_host: true
  end

  private

  # O destino vem do banco, preenchido no painel — mas validamos mesmo assim.
  # Um open redirect transformaria este domínio em trampolim para phishing, e
  # confiar na origem do dado é exatamente o erro que essa classe de falha explora.
  ALLOWED_SCHEMES = %w[http https].freeze
  ALLOWED_HOSTS = %w[wa.me api.whatsapp.com instagram.com www.instagram.com].freeze

  def safe_target(link)
    candidate = link.target_url.presence || fallback_url
    return fallback_url unless permitted?(candidate)

    candidate
  end

  def permitted?(url)
    uri = URI.parse(url)
    return false unless ALLOWED_SCHEMES.include?(uri.scheme)
    return true if uri.host.in?(ALLOWED_HOSTS)

    # Landing pages do próprio sistema.
    uri.host.to_s.end_with?(app_domain)
  rescue URI::InvalidURIError
    false
  end

  def app_domain = ENV.fetch("APP_DOMAIN", "lvh.me:3000").split(":").first

  def track(link)
    # Preview do Instagram e bots não são visitas reais.
    return if bot?

    link.link_clicks.create!(
      referrer: request.referer&.first(500),
      user_agent: request.user_agent&.first(255),
      ip_hash: hashed_ip,
      clicked_at: Time.current
    )
    ShortLink.where(id: link.id).update_all("click_count = click_count + 1")
  rescue StandardError => e
    Rails.logger.warn("[Redirect] falha ao registrar clique: #{e.message}")
  end

  def bot?
    request.user_agent.to_s.match?(/bot|crawler|spider|facebookexternalhit|instagram|whatsapp|preview/i)
  end

  # Nunca IP em claro: só hash com salt, o que mantém a tabela fora do
  # escopo de dado pessoal.
  def hashed_ip
    return if request.remote_ip.blank?

    salt = Rails.application.secret_key_base.first(16)
    Digest::SHA256.hexdigest("#{salt}#{request.remote_ip}").first(32)
  end

  def fallback_url = ENV.fetch("FALLBACK_URL", "https://instagram.com")
end
