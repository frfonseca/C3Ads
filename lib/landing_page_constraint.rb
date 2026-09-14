# Resolve o subdomínio para uma LandingPage publicada.
#
# Roda em toda requisição, por isso consulta com cache. Subdomínio que não
# casa cai fora da constraint e recebe 404 — não um erro de roteamento.
class LandingPageConstraint
  RESERVED = %w[app www api mail admin r assets cdn static].freeze

  def matches?(request)
    subdomain = request.subdomain.to_s.downcase
    return false if subdomain.blank? || subdomain.in?(RESERVED)

    Rails.cache.fetch("landing_page_slug/#{subdomain}", expires_in: 1.minute) do
      defined?(LandingPage) && LandingPage.where(slug: subdomain, state: "published").exists?
    end
  end
end
