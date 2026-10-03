require "landing_page_constraint"

Rails.application.routes.draw do
  # Painel — app.<dominio>, autenticado.
  constraints(subdomain: ENV.fetch("ADMIN_SUBDOMAIN", "app")) do
    root "projects#index", as: :root

    resource :session, only: %i[new create destroy]

    get  "/saude", to: "health#show", as: :health
    post "/saude/:id/resolver", to: "health#resolve", as: :resolve_health

    resources :projects do
      resources :assets, only: %i[index create update destroy]
      resource  :brand,  only: %i[edit update]
      resources :posts,  only: %i[index show new create edit update destroy] do
        member do
          post :approve
          post :reject
          post :regenerate
          get  :export
        end
      end
    end

    mount Sidekiq::Web => "/sidekiq" if defined?(Sidekiq::Web)
  end

  # Link curto — vive no domínio raiz, curto de propósito.
  get "/r/:slug", to: "redirects#show", as: :short_link

  # Landing pages — cada uma no seu subdomínio.
  constraints(LandingPageConstraint.new) do
    root "public/pages#show", as: :landing_page
    get  "/privacidade", to: "public/pages#privacy", as: :landing_page_privacy
    post "/leads", to: "public/leads#create", as: :landing_page_leads
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
