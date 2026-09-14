# Identidade do projeto: visual (cores, fontes, logo) e verbal (tom de voz).
#
# Não é só um depósito — é aplicada automaticamente. As cores viram CSS custom
# properties nas landing pages, e o tom de voz entra no system prompt do LLM.
class Brand < ApplicationRecord
  belongs_to :project
  belongs_to :logo_asset,      class_name: "Asset", optional: true
  belongs_to :logo_dark_asset, class_name: "Asset", optional: true
  belongs_to :favicon_asset,   class_name: "Asset", optional: true

  HEX = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/

  %i[primary_color secondary_color accent_color text_color background_color].each do |attr|
    validates attr, format: { with: HEX, message: "deve ser hex (#rrggbb)" }, allow_blank: true
  end

  # Cores expostas como CSS custom properties — trocar a cor da marca
  # muda todas as páginas do projeto de uma vez.
  def css_variables
    {
      "--brand-primary"    => primary_color,
      "--brand-secondary"  => secondary_color,
      "--brand-accent"     => accent_color,
      "--brand-text"       => text_color,
      "--brand-background" => background_color,
      "--brand-heading-font" => "#{heading_font.inspect}, system-ui, sans-serif",
      "--brand-body-font"    => "#{body_font.inspect}, system-ui, sans-serif"
    }.compact
  end

  def css_variables_style
    css_variables.map { |k, v| "#{k}: #{v};" }.join(" ")
  end

  # Trecho de identidade verbal injetado no system prompt do gerador.
  def prompt_instructions
    parts = []
    parts << "Tom de voz: #{tone_of_voice}" if tone_of_voice.present?
    parts << "Prefira mencionar: #{do_say.join(', ')}" if do_say.any?
    parts << "NUNCA use estes termos: #{dont_say.join(', ')}" if dont_say.any?
    parts << "Assinatura/CTA padrão: #{signature}" if signature.present?
    parts.join("\n")
  end
end
