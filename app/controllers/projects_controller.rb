class ProjectsController < AdminController
  before_action :set_project, only: %i[show edit update destroy]

  def index
    @projects = Project.order(:name)
  end

  def show
    @pending_posts = @project.posts.pending_review.order(created_at: :desc)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project, notice: "Projeto criado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Projeto atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to root_path, notice: "Projeto removido."
  end

  private

  def set_project = @project = Project.find(params[:id])

  def project_params
    params.expect(project: [:name, :kind, :description, :whatsapp_number,
                            :llm_provider, :llm_model, :monthly_cost_limit_usd, :active])
  end
end
