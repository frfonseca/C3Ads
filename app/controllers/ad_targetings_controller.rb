class AdTargetingsController < AdminController
  before_action :set_project

  def index
    @targetings = @project.ad_targetings.order(:name)
  end

  def create
    @project.ad_targetings.create!(targeting_params)
    redirect_to project_ad_targetings_path(@project), notice: "Público salvo."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to project_ad_targetings_path(@project), alert: e.record.errors.full_messages.to_sentence
  end

  def update
    @project.ad_targetings.find(params[:id]).update!(targeting_params)
    redirect_to project_ad_targetings_path(@project), notice: "Público atualizado."
  end

  def destroy
    @project.ad_targetings.find(params[:id]).destroy
    redirect_to project_ad_targetings_path(@project), notice: "Público removido."
  end

  private

  def set_project = @project = Project.find(params[:project_id])

  def targeting_params
    params.expect(ad_targeting: [ :name, :latitude, :longitude, :radius_km,
                                 :age_min, :age_max, countries: [], genders: [], interests: [] ])
  end
end
