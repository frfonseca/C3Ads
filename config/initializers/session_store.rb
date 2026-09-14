# O cookie de sessão fica preso ao subdomínio do painel — NUNCA ao domínio-pai.
#
# Com `domain: :all` ou ".dominio", o cookie autenticado seria enviado também
# às landing pages públicas, que recebem formulários de gente desconhecida.
# Esta é a razão técnica de o painel viver em `app.`.
admin_host = ENV.fetch("ADMIN_HOST", "app.lvh.me")

Rails.application.config.session_store :cookie_store,
                                       key: "_c3ads_session",
                                       domain: admin_host.split(":").first,
                                       same_site: :lax,
                                       secure: Rails.env.production?
