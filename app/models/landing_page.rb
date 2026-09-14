# Página pública do projeto.
#
# `post_id` vazio = página permanente (a da casa, que vários posts referenciam
# por semanas). Preenchido = página daquela campanha (a promoção do dia de
# chuva). Mesmo modelo: o vínculo expressa tempo de vida, não tipo.
class LandingPage < ApplicationRecord
  include AASM

  KINDS = %w[property local_business promotion lead_capture].freeze

  # Subdomínios que o sistema usa — uma página não pode sequestrá-los.
  RESERVED_SLUGS = LandingPageConstraint::RESERVED

  belongs_to :project
  belongs_to :post, optional: true

  has_many :landing_media, -> { order(:position) }, dependent: :destroy, inverse_of: :landing_page
  has_many :assets, through: :landing_media
  has_many :page_views, dependent: :destroy
  has_many :leads, dependent: :nullify

  attribute :blocks, ActiveRecord::Type::Json.new, default: -> { {} }

  validates :kind, inclusion: { in: KINDS }
  # Slug vira nome de host: regras de hostname, não de URL.
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/,
                             message: "deve conter apenas letras minúsculas, números e hífen" },
                   exclusion: { in: RESERVED_SLUGS, message: "é reservado pelo sistema" }

  before_validation :normalize_slug
  before_update :remember_previous_slug, if: :slug_changed?

  aasm column: :state do
    state :draft, initial: true
    state :generating, :pending_review, :published, :archived

    event :start_generation do
      transitions from: [ :draft, :pending_review ], to: :generating
    end

    event :finish_generation do
      transitions from: :generating, to: :pending_review
    end
    event :publish do
      transitions from: :pending_review, to: :published
      after { update_column(:published_at, Time.current) }
    end
    event :archive do
      transitions from: [ :published, :pending_review, :draft ], to: :archived
    end
  end

  scope :permanent, -> { where(post_id: nil) }
  scope :live, -> { where(state: "published") }

  def expired? = expires_at.present? && expires_at.past?

  # Só assets públicos aparecem. A checagem vive aqui, não só no formulário.
  def public_assets = assets.publicly_visible

  def host(domain = ENV.fetch("APP_DOMAIN", "lvh.me:3000")) = "#{slug}.#{domain}"

  private

  def normalize_slug
    self.slug = slug.to_s.downcase.strip.parameterize.presence
  end

  def remember_previous_slug
    # Slug antigo continua redirecionando: o que já circulou não pode quebrar.
    self.previous_slugs = (previous_slugs + [ slug_was ]).compact.uniq
  end
end
