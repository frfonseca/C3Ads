module Video
  # Monta a spec do slideshow e renderiza com ffmpeg.
  #
  # Duas decisões que importam mais que o código:
  # - Sem áudio por padrão. Música comercial em anúncio é risco de direito
  #   autoral e derrubada do post; o Instagram permite adicionar som nativo
  #   depois da publicação, que inclusive alcança melhor.
  # - Renderização fora do processo web, em fila própria com concorrência 1:
  #   ffmpeg satura CPU e a VPS tem 2 vCPU.
  class SlideshowBuilder
    WIDTH = 1080
    HEIGHT = 1920          # 9:16, formato do Reels
    SECONDS_PER_PHOTO = 3
    MIN_DURATION = 3       # mínimo aceito pelo Reels
    MAX_DURATION = 90

    class FfmpegMissing < StandardError; end

    def self.available? = ENV["VIDEO_FAKE"] != "true" && system("which ffmpeg > /dev/null 2>&1")

    def initialize(post, seconds_per_photo: SECONDS_PER_PHOTO)
      @post = post
      @seconds = seconds_per_photo
    end

    # A spec é dado, não efeito colateral: pode ser inspecionada e ajustada
    # antes de gastar CPU renderizando.
    def spec
      media = @post.post_media.includes(:asset).to_a
      highlights = Array(@post.generation_meta["highlights"])
      brand = @post.project.brand

      {
        "width" => WIDTH,
        "height" => HEIGHT,
        "seconds_per_photo" => @seconds,
        "duration" => [ [ media.size * @seconds, MIN_DURATION ].max, MAX_DURATION ].min,
        "audio" => nil,
        "slides" => media.each_with_index.map do |item, index|
          {
            "asset_id" => item.asset_id,
            "position" => index,
            "caption" => highlights[index],
            "ken_burns" => true
          }
        end,
        "brand" => {
          "primary" => brand&.primary_color,
          "accent" => brand&.accent_color,
          "logo_asset_id" => brand&.logo_asset_id
        }
      }
    end

    def render!(output_path)
      raise FfmpegMissing, "ffmpeg não está instalado" unless self.class.available?

      Dir.mktmpdir do |dir|
        list = write_frames(dir)
        run_ffmpeg(list, output_path)
      end
      output_path
    end

    private

    def write_frames(dir)
      paths = @post.post_media.includes(:asset).map.with_index do |item, index|
        path = File.join(dir, format("frame-%03d.jpg", index))
        File.binwrite(path, item.asset.file.download)
        path
      end

      list_path = File.join(dir, "frames.txt")
      File.write(list_path, paths.flat_map { |p| [ "file '#{p}'", "duration #{@seconds}" ] }
                                 .push("file '#{paths.last}'").join("\n"))
      list_path
    end

    def run_ffmpeg(list_path, output_path)
      filter = "scale=#{WIDTH}:#{HEIGHT}:force_original_aspect_ratio=increase," \
               "crop=#{WIDTH}:#{HEIGHT},format=yuv420p"

      command = [
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", list_path,
        "-vf", filter, "-r", "30", "-c:v", "libx264", "-preset", "medium",
        "-movflags", "+faststart", output_path
      ]

      success = system(*command, out: File::NULL, err: File::NULL)
      raise "ffmpeg falhou ao renderizar" unless success
    end
  end
end
