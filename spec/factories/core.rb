FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Conta #{n}" }
    ig_user_id { "1784#{rand(100000..999999)}" }
    ig_username { "negocio_teste" }
    access_token { "fake-token" }
    token_expires_at { 60.days.from_now }
  end

  factory :project do
    sequence(:name) { |n| "Projeto #{n}" }
    kind { "generic" }

    trait :property do
      kind { "property" }
      name { "Casa Rua X" }
    end

    trait :laundry do
      kind { "local_business" }
      name { "Lavanderia Centro" }
    end
  end

  factory :asset do
    project
    kind { "photo" }
    visibility { "private" }
    sequence(:title) { |n| "Foto #{n}" }

    after(:build) do |asset|
      asset.file.attach(
        io: StringIO.new(TestImages.png_bytes),
        filename: "foto.png",
        content_type: "image/png"
      )
    end

    trait :public_asset do
      visibility { "public" }
    end

    trait :logo do
      kind { "logo" }
    end

    trait :document do
      kind { "document" }
    end
  end

  factory :asset_collection do
    project
    sequence(:name) { |n| "Coleção #{n}" }
  end

  factory :post do
    project
    media_type { "carousel" }
    caption { "Legenda de teste" }

    trait :pending_review do
      state { "pending_review" }
    end

    trait :approved do
      state { "approved" }
      approved_at { Time.current }
      approved_by { "frederico" }
    end

    trait :scheduled do
      state { "scheduled" }
      approved_at { Time.current }
      approved_by { "frederico" }
      scheduled_for { 1.hour.from_now }
    end
  end
end

# 1x1 PNG válido — evita depender de fixture em disco.
module TestImages
  PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==".freeze
  def self.png_bytes = Base64.decode64(PNG)
end
