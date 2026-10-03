# Autenticação mínima: uma senha única, já que o sistema tem um só usuário.
module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
    helper_method :signed_in?
  end

  private

  def signed_in? = session[:admin].present?

  def require_admin
    return if signed_in?

    session[:return_to] = request.fullpath
    redirect_to new_session_path, alert: "Faça login para continuar."
  end
end
