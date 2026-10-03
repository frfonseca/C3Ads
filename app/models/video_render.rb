# Slideshow montado a partir das fotos do post.
#
# A spec é derivada da ordem que o LLM já escolheu e dos destaques que ele já
# identificou — o vídeo herda essa curadoria sem trabalho extra.
class VideoRender < ApplicationRecord
  include AASM

  belongs_to :post
  belongs_to :asset, optional: true

  attribute :spec, ActiveRecord::Type::Json.new, default: -> { {} }

  aasm column: :state do
    state :pending, initial: true
    state :rendering, :done, :failed

    event :start do
      transitions from: [ :pending, :failed ], to: :rendering
    end

    event :finish do
      transitions from: :rendering, to: :done
    end

    event :fail do
      transitions from: :rendering, to: :failed
    end
  end
end
