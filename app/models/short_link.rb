class ShortLink < ApplicationRecord
  belongs_to :post, optional: true
  belongs_to :destination, optional: true
  has_many :link_clicks, dependent: :destroy
  has_many :page_views, dependent: :nullify

  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  def target_url
    destination&.url || post&.project&.whatsapp_url
  end

  private

  def generate_slug
    self.slug ||= loop do
      candidate = SecureRandom.alphanumeric(6).downcase
      break candidate unless ShortLink.exists?(slug: candidate)
    end
  end
end
