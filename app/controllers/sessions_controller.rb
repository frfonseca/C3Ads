class SessionsController < ApplicationController
  def new; end

  def create
    if ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(params[:password].to_s),
      ::Digest::SHA256.hexdigest(ENV.fetch("ADMIN_PASSWORD", "troque-me"))
    )
      session[:admin] = true
      redirect_to session.delete(:return_to) || root_path, notice: "Bem-vindo."
    else
      flash.now[:alert] = "Senha incorreta."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Sessão encerrada."
  end
end
