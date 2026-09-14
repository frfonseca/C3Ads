# A unidade da esteira de publicação.
#
# A state machine abaixo carrega a invariante central do projeto: nada é
# publicado sem revisão humana. O guard `approved?` é aplicado no modelo, não
# na interface — é o que garante que nenhum caminho de código (job, console,
# gatilho automático) consiga publicar conteúdo não aprovado.
class Post < ApplicationRecord
  include AASM

  MEDIA_TYPES = %w[image carousel reel story].freeze
  CAROUSEL_LIMIT = 10

  belongs_to :project
  belongs_to :account, optional: true

  has_many :post_media, -> { order(:position) }, dependent: :destroy, inverse_of: :post
  has_many :assets, through: :post_media

  # Default na aplicação, não no banco: o schema dumper do Rails 8.1 omite
  # silenciosamente qualquer tabela com coluna jsonb que tenha DEFAULT.
  attribute :generation_meta, ActiveRecord::Type::Json.new, default: -> { {} }

  validates :media_type, inclusion: { in: MEDIA_TYPES }
  validate  :carousel_within_limit

  scope :pending_review, -> { where(state: "pending_review") }
  scope :publishable,    -> { where(state: "scheduled") }

  aasm column: :state do
    state :draft, initial: true
    state :generating, :pending_review, :approved, :scheduled,
          :publishing, :published, :rejected, :canceled, :failed

    event :start_generation do
      transitions from: [ :draft, :pending_review ], to: :generating
    end

    event :finish_generation do
      transitions from: :generating, to: :pending_review
    end

    event :fail_generation do
      transitions from: :generating, to: :draft
    end

    # Único ponto onde a aprovação humana é registrada.
    event :approve do
      transitions from: :pending_review, to: :approved, guard: :approval_recorded?
    end

    event :reject do
      transitions from: [ :pending_review, :approved ], to: :rejected
    end

    # O guard se repete de propósito: agendar é o passo que leva à publicação,
    # e não deve depender de `approve` ter sido o caminho percorrido.
    event :schedule do
      transitions from: :approved, to: :scheduled, guard: :approval_recorded?
    end

    event :start_publishing do
      transitions from: [ :scheduled, :failed ], to: :publishing, guard: :approval_recorded?
    end

    event :mark_published do
      transitions from: :publishing, to: :published
    end

    event :mark_failed do
      transitions from: :publishing, to: :failed
    end

    event :cancel do
      transitions from: [ :approved, :scheduled, :failed ], to: :canceled
    end
  end

  # Registra a aprovação e transiciona. Passar por aqui é a forma suportada
  # de aprovar: preenche quem aprovou e quando, que é o que o guard exige.
  def approve_by!(approver, scheduled_for: nil)
    raise ArgumentError, "approver é obrigatório" if approver.blank?

    transaction do
      update!(approved_at: Time.current, approved_by: approver,
              scheduled_for: scheduled_for || self.scheduled_for)
      approve!
    end
  end

  def approval_recorded?
    approved_at.present? && approved_by.present?
  end

  def carousel? = media_type == "carousel"
  def video?    = media_type.in?(%w[reel story])

  private

  def carousel_within_limit
    return unless carousel? && post_media.size > CAROUSEL_LIMIT

    errors.add(:base, "carrossel do Instagram aceita no máximo #{CAROUSEL_LIMIT} itens")
  end
end
