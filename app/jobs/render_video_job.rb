# Renderiza o slideshow. Fila própria com concorrência 1: ffmpeg satura CPU e
# não pode competir com publicação e gatilhos numa VPS de 2 vCPU.
class RenderVideoJob < ApplicationJob
  queue_as :video

  def perform(video_render_id)
    render = VideoRender.find(video_render_id)
    return unless render.may_start?

    render.start!
    builder = Video::SlideshowBuilder.new(render.post)
    render.update!(spec: builder.spec, duration_seconds: builder.spec["duration"])

    unless Video::SlideshowBuilder.available?
      # Sem ffmpeg o sistema continua utilizável: o post segue como carrossel.
      render.update!(error_message: "ffmpeg indisponível neste ambiente")
      render.fail!
      return
    end

    attach_video!(render, builder)
    render.finish!
  rescue StandardError => e
    Rails.logger.error("[RenderVideoJob] #{e.class}: #{e.message}")
    render&.update(error_message: e.message)
    render&.fail! if render&.may_fail?
    raise
  end

  private

  def attach_video!(render, builder)
    Dir.mktmpdir do |dir|
      output = File.join(dir, "slideshow-#{render.post_id}.mp4")
      builder.render!(output)

      asset = render.post.project.assets.create!(
        kind: "video",
        visibility: "internal",
        title: "Slideshow do post ##{render.post_id}",
        file: { io: File.open(output), filename: File.basename(output), content_type: "video/mp4" }
      )
      render.update!(asset:)
    end
  end
end
