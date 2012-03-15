class ArtigosDeEventoController < InheritedResources::Base
  actions :new, :create, :show, :edit, :update, :aprovar

  include NovoComAutor
  include WorkflowActions

  before_filter :authenticate_usuario!
  load_and_authorize_resource

  def create
    create! notice: 'Artigo de evento submetido com sucesso'
  end
end
