# Qualquer material do projeto: logo, foto, vídeo ou documento.
#
# `visibility` é o campo mais sensível do modelo. Documentos como matrícula de
# imóvel carregam dados pessoais, e landing pages são indexáveis — por isso o
# padrão é `private` e só `public` é exposto pelos templates públicos.
class Asset < ApplicationRecord
  KINDS = %w[logo photo video document].freeze
  VISIBILITIES = %w[private internal public].freeze

  belongs_to :project

  has_one_attached :file

  has_many :asset_collection_memberships, dependent: :destroy
  has_many :asset_collections, through: :asset_collection_memberships
  has_many :post_media, dependent: :restrict_with_error

  # Default na aplicação, não no banco: o schema dumper do Rails 8.1 omite
  # silenciosamente qualquer tabela com coluna jsonb que tenha DEFAULT.
  attribute :vision_analysis, ActiveRecord::Type::Json.new, default: -> { {} }

  validates :kind, inclusion: { in: KINDS }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validates :file, presence: true

  scope :photos,    -> { where(kind: "photo") }
  scope :logos,     -> { where(kind: "logo") }
  scope :videos,    -> { where(kind: "video") }
  scope :documents, -> { where(kind: "document") }

  # O único escopo que templates públicos devem usar.
  scope :publicly_visible, -> { where(visibility: "public") }

  scope :usable, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :least_recently_used, -> { order(Arel.sql("last_used_at NULLS FIRST")) }

  def public? = visibility == "public"

  def analyzed? = vision_analysis.present?

  def record_use!
    update_columns(usage_count: usage_count + 1, last_used_at: Time.current)
  end
end
