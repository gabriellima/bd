class ArtigosDePeriodicoController < InheritedResources::Base
  actions :new, :create, :show

  include NovoComAutor

  before_filter :authenticate_usuario!
  load_and_authorize_resource

  def create
    create! notice: 'Artigo de periodico submetido com sucesso'
  end
end
