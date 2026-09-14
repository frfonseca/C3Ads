# Para onde o post manda. Escolhido na aprovação, por post.
class Destination < ApplicationRecord
  KINDS = %w[whatsapp landing profile].freeze

  belongs_to :post, optional: true
  belongs_to :landing_page, optional: true

  validates :kind, inclusion: { in: KINDS }

  def url
    case kind
    when "whatsapp" then whatsapp_url
    when "landing"  then landing_page && "https://#{landing_page.host}"
    end
  end

  private

  def whatsapp_url
    return if whatsapp_number.blank?

    digits = whatsapp_number.gsub(/\D/, "")
    text = prefilled_message.presence
    text ? "https://wa.me/#{digits}?text=#{CGI.escape(text)}" : "https://wa.me/#{digits}"
  end
end
