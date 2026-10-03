# Base de tudo que vive em app.<dominio> — sempre autenticado.
class AdminController < ApplicationController
  include AdminAuthentication
end
