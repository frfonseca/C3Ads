class PostsController < AdminController
  before_action :set_project
  before_action :set_post, only: %i[show edit update destroy approve reject regenerate export]

  def index
    @posts = @project.posts.order(created_at: :desc)
    @posts = @posts.where(state: params[:state]) if params[:state].present?
  end

  def show; end
  def edit; end

  def new
    @post = @project.posts.new
  end

  def create
    @post = @project.posts.new(post_params)
    if @post.save
      GeneratePostJob.perform_later(@post.id, context: params[:context].presence)
      redirect_to [ @project, @post ], notice: "Gerando conteúdo…"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      redirect_to [ @project, @post ], notice: "Post atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Aprovar é o único caminho suportado para liberar publicação: registra quem
  # aprovou e quando, que é o que o guard da state machine exige.
  def approve
    @post.approve_by!(current_approver, scheduled_for: scheduled_for_param)
    @post.schedule! if @post.scheduled_for.present? && @post.may_schedule?

    redirect_to [ @project, @post ], notice: "Aprovado."
  rescue AASM::InvalidTransition, ArgumentError => e
    redirect_to [ @project, @post ], alert: "Não foi possível aprovar: #{e.message}"
  end

  def reject
    @post.reject!
    redirect_to project_posts_path(@project), notice: "Post rejeitado."
  end

  # Reenvia ao LLM com o feedback do revisor — o loop de refino acontece aqui,
  # não no prompt inicial.
  def regenerate
    GeneratePostJob.perform_later(@post.id, feedback: params[:feedback].presence)
    redirect_to [ @project, @post ], notice: "Regenerando com seu feedback…"
  end

  # Saída de emergência: se o sistema estiver fora do ar ou a Meta rejeitar,
  # a curadoria não se perde — publica-se pelo celular a partir do zip.
  def export
    zip = Posts::Exporter.new(@post).call
    send_data zip.string, filename: "post-#{@post.id}.zip", type: "application/zip"
  end

  def destroy
    @post.destroy
    redirect_to project_posts_path(@project), notice: "Post removido."
  end

  private

  def set_project = @project = Project.find(params[:project_id])
  def set_post    = @post = @project.posts.find(params[:id])

  def current_approver = session[:admin_name].presence || "admin"

  def scheduled_for_param
    return if params[:scheduled_for].blank?

    Time.zone.parse(params[:scheduled_for])
  end

  def post_params
    permitted = params.expect(post: [ :caption, :media_type, :scheduled_for, :hashtags_text ])
    raw = permitted.delete(:hashtags_text)
    unless raw.nil?
      permitted[:hashtags] = raw.to_s.scan(/[[:alnum:]_]+/).first(30)
    end
    permitted
  end
end
