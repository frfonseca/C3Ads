class PostMetric < ApplicationRecord
  belongs_to :post

  # Salvamentos e compartilhamentos são o sinal forte: curtida é barata,
  # salvar um anúncio de imóvel é intenção real.
  def engagement = likes.to_i + comments.to_i + saved.to_i + shares.to_i
end
