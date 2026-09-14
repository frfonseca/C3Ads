class BrandsController < AdminController
  before_action :set_project

  def edit
    @brand = @project.brand
  end

  def update
    @brand = @project.brand
    if @brand.update(brand_params)
      redirect_to edit_project_brand_path(@project), notice: "Marca atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_project = @project = Project.find(params[:project_id])

  def brand_params
    permitted = params.expect(brand: [ :primary_color, :secondary_color, :accent_color,
                                      :text_color, :background_color, :heading_font, :body_font,
                                      :tone_of_voice, :signature, :watermark_posts,
                                      :logo_asset_id, :logo_dark_asset_id, :favicon_asset_id,
                                      :do_say_text, :dont_say_text, :default_hashtags_text ])
    # Campos de lista chegam como texto (uma entrada por linha) para facilitar a edição.
    %i[do_say dont_say default_hashtags].each do |field|
      raw = permitted.delete(:"#{field}_text")
      permitted[field] = raw.to_s.split("\n").map(&:strip).reject(&:blank?) unless raw.nil?
    end
    permitted
  end
end
