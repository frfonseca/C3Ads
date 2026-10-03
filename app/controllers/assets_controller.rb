class AssetsController < AdminController
  before_action :set_project

  def index
    @assets = @project.assets.order(created_at: :desc)
    @assets = @assets.where(kind: params[:kind]) if params[:kind].present?
    @assets = @assets.where("tags @> ARRAY[?]::varchar[]", [ params[:tag] ]) if params[:tag].present?
  end

  def create
    # Upload múltiplo: cada arquivo vira um Asset, sempre privado por padrão.
    files = Array(params[:files]).reject(&:blank?)
    created = files.map do |file|
      @project.assets.create!(
        kind: params[:kind].presence || "photo",
        title: file.original_filename,
        file: file
      )
    end
    redirect_to project_assets_path(@project), notice: "#{created.size} arquivo(s) enviado(s)."
  end

  def update
    asset = @project.assets.find(params[:id])
    asset.update!(asset_params)
    redirect_to project_assets_path(@project), notice: "Asset atualizado."
  end

  def destroy
    @project.assets.find(params[:id]).destroy
    redirect_to project_assets_path(@project), notice: "Asset removido."
  end

  private

  def set_project = @project = Project.find(params[:project_id])

  def asset_params
    permitted = params.expect(asset: [ :kind, :visibility, :title, :notes, :expires_at, :tags_text ])
    raw = permitted.delete(:tags_text)
    permitted[:tags] = raw.to_s.split(",").map(&:strip).reject(&:blank?) unless raw.nil?
    permitted
  end
end
