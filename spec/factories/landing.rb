FactoryBot.define do
  factory :landing_page do
    project
    sequence(:slug) { |n| "pagina-#{n}" }
    kind { "lead_capture" }
    title { "Página de teste" }
    blocks { { "headline" => "Título", "subheadline" => "Sub" } }

    trait :published do
      state { "published" }
      published_at { Time.current }
    end

    trait :property do
      kind { "property" }
    end

    trait :expired do
      state { "published" }
      kind { "promotion" }
      expires_at { 1.day.ago }
    end
  end

  factory :short_link do
    sequence(:slug) { |n| "lnk#{n}" }
  end

  factory :destination do
    kind { "whatsapp" }
    whatsapp_number { "+55 11 99999-0000" }
  end

  factory :lead do
    project
    name { "Maria" }
    phone { "11999990000" }
    consent_text { "Autorizo o contato." }
    consent_at { Time.current }
  end
end
