# Público-alvo. As validações refletem o que a Meta aceita, e não apenas o que
# o formulário pede: montar um público inválido só falharia na hora de gastar.
class AdTargeting < ApplicationRecord
  # Restrições da Special Ad Category HOUSING (anúncios de imóveis).
  HOUSING_MIN_RADIUS_KM = 25

  belongs_to :project
  has_many :ad_campaigns, dependent: :nullify

  validates :radius_km, numericality: { greater_than: 0 }, allow_nil: true

  validate :housing_restrictions, if: :housing?

  def housing?
    project&.property? || ad_campaigns.any? { _1.special_ad_category == "HOUSING" }
  end

  def to_meta_hash(special_ad_category: nil)
    housing = special_ad_category == "HOUSING"
    hash = { "geo_locations" => geo_locations(housing) }

    unless housing
      hash["age_min"] = age_min if age_min
      hash["age_max"] = age_max if age_max
      hash["genders"] = genders.map(&:to_i) if genders.any?
    end

    hash["flexible_spec"] = [ { "interests" => interests } ] if interests.any?
    hash
  end

  private

  def geo_locations(housing)
    radius = housing ? [ radius_km.to_i, HOUSING_MIN_RADIUS_KM ].max : radius_km
    if latitude && longitude && radius
      { "custom_locations" => [ { "latitude" => latitude.to_f, "longitude" => longitude.to_f,
                                 "radius" => radius, "distance_unit" => "kilometer" } ] }
    else
      { "countries" => countries }
    end
  end

  def housing_restrictions
    if radius_km.present? && radius_km < HOUSING_MIN_RADIUS_KM
      errors.add(:radius_km, "mínimo de #{HOUSING_MIN_RADIUS_KM} km — exigência da Meta para anúncios de imóveis")
    end
    errors.add(:genders, "não pode ser segmentado em anúncios de imóveis") if genders.any?
    if age_min.present? || age_max.present?
      errors.add(:age_min, "idade não pode ser segmentada em anúncios de imóveis")
    end
  end
end
