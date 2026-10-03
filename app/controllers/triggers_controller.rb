class TriggersController < AdminController
  before_action :set_project

  def index
    @triggers = @project.triggers.order(:kind, :name)
    @recent_events = TriggerEvent.joins(:trigger).where(triggers: { project_id: @project.id })
                                 .order(evaluated_at: :desc).limit(20)
  end

  def create
    @project.triggers.create!(trigger_params)
    redirect_to project_triggers_path(@project), notice: "Gatilho criado."
  end

  def update
    @project.triggers.find(params[:id]).update!(trigger_params)
    redirect_to project_triggers_path(@project), notice: "Gatilho atualizado."
  end

  def destroy
    @project.triggers.find(params[:id]).destroy
    redirect_to project_triggers_path(@project), notice: "Gatilho removido."
  end

  # "Gerar post agora": isento de cooldown — se a pessoa clicou, ela quis.
  def fire
    trigger = @project.triggers.find(params[:id])
    evaluator = Triggers::Manual.new(trigger, note: params[:note].presence)

    post = @project.posts.create!(media_type: "carousel", account: @project.account)
    GeneratePostJob.perform_later(post.id, context: evaluator.context["note"])
    trigger.trigger_events.create!(fired: true, post:, reason: evaluator.reason,
                                   context: evaluator.context, evaluated_at: Time.current)

    redirect_to [ @project, post ], notice: "Gerando post…"
  end

  private

  def set_project = @project = Project.find(params[:project_id])

  def trigger_params
    permitted = params.expect(trigger: [ :kind, :name, :cooldown_hours, :active,
                                        :latitude, :longitude, :metric, :op, :value,
                                        :horizon_hours, :cron ])
    condition = permitted.extract!(:latitude, :longitude, :metric, :op, :value, :horizon_hours, :cron)
                         .compact_blank
    permitted.merge(condition: condition)
  end
end
