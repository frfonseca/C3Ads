class AdCampaignsController < AdminController
  before_action :set_project

  def index
    @campaigns = @project.ad_campaigns.order(created_at: :desc)
  end

  def new
    @campaign = @project.ad_campaigns.new
    @targetings = @project.ad_targetings
  end

  def create
    @campaign = @project.ad_campaigns.new(campaign_params)
    if @campaign.save && Ads::Publisher.new(@campaign).call
      redirect_to project_ad_campaigns_path(@project),
                  notice: "Campanha criada e PAUSADA na Meta. Ative quando quiser começar a gastar."
    else
      @targetings = @project.ad_targetings
      render :new, status: :unprocessable_entity
    end
  end

  # Ativar é o passo que gasta dinheiro — deliberado e separado da criação.
  def activate
    campaign = @project.ad_campaigns.find(params[:id])
    campaign.activate!
    redirect_to project_ad_campaigns_path(@project),
                notice: "Campanha ATIVA. O orçamento diário começa a ser gasto agora."
  end

  def pause
    campaign = @project.ad_campaigns.find(params[:id])
    campaign.pause!
    redirect_to project_ad_campaigns_path(@project), notice: "Campanha pausada."
  end

  private

  def set_project = @project = Project.find(params[:project_id])

  def campaign_params
    params.expect(ad_campaign: [ :name, :objective, :special_ad_category,
                                :daily_budget_cents, :ad_targeting_id, :post_id ])
  end
end
