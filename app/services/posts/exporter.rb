require "zip"

module Posts
  # Empacota um post aprovado para publicação manual.
  #
  # Existe para o caso de o sistema estar fora do ar, o token vencer num fim de
  # semana, ou a Meta rejeitar algo: a curadoria (ordem das fotos, legenda,
  # hashtags) não se perde, e o post vai ao ar pelo celular em dois minutos.
  class Exporter
    def initialize(post)
      @post = post
    end

    def call
      buffer = Zip::OutputStream.write_buffer(StringIO.new) do |zip|
        zip.put_next_entry("legenda.txt")
        zip.write(caption_text)

        @post.post_media.each_with_index do |media, index|
          next unless media.asset.file.attached?

          zip.put_next_entry(filename_for(media, index))
          zip.write(media.asset.file.download)
        end
      end
      buffer.tap(&:rewind)
    end

    private

    # Fotos numeradas na ordem aprovada: é assim que a curadoria sobrevive
    # fora do sistema.
    def filename_for(media, index)
      ext = File.extname(media.asset.file.filename.to_s).presence || ".jpg"
      format("%02d-%s%s", index + 1, media.asset.title.to_s.parameterize.presence || "foto", ext)
    end

    def caption_text
      [
        @post.caption,
        "",
        @post.hashtags.map { |h| "##{h}" }.join(" ")
      ].join("\n")
    end
  end
end
