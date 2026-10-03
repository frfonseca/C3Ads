module Public
  # Landing page servida na raiz do seu próprio subdomínio.
  class PagesController < ApplicationController
    layout "public"

    def show
      @page = LandingPage.find_by(slug: request.subdomain.to_s.downcase)
      return render_not_found if @page.nil?

      # Página de promoção vencida não dá 404 seco: explica e oferece saída.
      return render(:expired, status: :gone) if @page.expired?

      @brand = @page.project.brand
      # Só assets públicos — a barreira contra vazar matrícula de imóvel.
      @media = @page.public_assets
      track_view(@page)
    end

    def privacy
      @page = LandingPage.find_by(slug: request.subdomain.to_s.downcase)
      @brand = @page&.project&.brand
    end

    private

    def track_view(page)
      return if bot?

      page.page_views.create!(
        short_link: ShortLink.find_by(slug: params[:ref]),
        referrer: request.referer&.first(500),
        ip_hash: hashed_ip,
        viewed_at: Time.current
      )
    rescue StandardError => e
      Rails.logger.warn("[PageView] #{e.message}")
    end

    def bot?
      request.user_agent.to_s.match?(/bot|crawler|spider|facebookexternalhit|preview/i)
    end

    def hashed_ip
      return if request.remote_ip.blank?

      salt = Rails.application.secret_key_base.first(16)
      Digest::SHA256.hexdigest("#{salt}#{request.remote_ip}").first(32)
    end

    def render_not_found
      render plain: "Página não encontrada", status: :not_found
    end
  end
end
