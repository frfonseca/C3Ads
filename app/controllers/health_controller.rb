# Tela de saúde: o que falhou e ainda não foi resolvido.
class HealthController < AdminController
  def show
    @alerts = SystemAlert.unresolved.order(created_at: :desc).limit(50)
    @failed_posts = Post.where(state: "failed").order(updated_at: :desc).limit(20)
    @accounts = Account.where.not(token_expires_at: nil).order(:token_expires_at)
    @month_costs = GenerationCost.this_month.group(:project_id).sum(:usd)
  end

  def resolve
    SystemAlert.find(params[:id]).resolve!
    redirect_to health_path, notice: "Alerta resolvido."
  end
end
