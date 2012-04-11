class Estatistica
  attr_reader :numero_de_usuarios_cadastrados, 
              :percentual_de_acessos_por_tipo_de_conteudo,
              :percentual_de_acessos_por_subarea_de_conhecimento,
              :instituicoes_que_mais_contribuiram,
              :campus_que_mais_contribuiram

  TIPOS_DE_CONTEUDO = [ArtigoDeEvento, ArtigoDePeriodico, Livro,
                       ObjetoDeAprendizagem, PeriodicoTecnicoCientifico,
                       Relatorio, TrabalhoDeObtencaoDeGrau]

  def initialize(ano, mes = nil)
    data_inicial = mes ? Time.new(ano, mes).beginning_of_month : Time.new(ano).beginning_of_year
    data_final = mes ? data_inicial.end_of_month : data_inicial.end_of_year
    @conteudos_validos = Conteudo.where(state: 'publicado')
    @numero_de_usuarios_cadastrados = usuarios(data_inicial, data_final)
    @percentual_de_acessos_por_tipo_de_conteudo = percentual_de_acessos_por_tipo_de_conteudo
    @percentual_de_acessos_por_subarea_de_conhecimento = cinco_maiores_percentuais_de_acessos_por_subarea
    @instituicoes_que_mais_contribuiram = instituicoes_contribuidoras
    @campus_que_mais_contribuiram = campus_contribuidores
  end

  def documentos_mais_acessados
    @conteudos_validos.all.sort_by(&:numero_de_acessos).reverse
  end

  def cinco_documentos_mais_acessados
    if documentos_mais_acessados.length < 5
      documentos_mais_acessados[0..documentos_mais_acessados.length]
    else
      documentos_mais_acessados[0..4]
    end
  end

  def percentual_de_acessos_por_tipo_de_conteudo
    percentuais = []
    unless @conteudos_validos.empty?
      TIPOS_DE_CONTEUDO.each do |tipo_atual|
        percentuais << [tipo_atual.to_s.underscore.humanize,
                        tipo_atual.all.sum(&:numero_de_acessos) /
                        @conteudos_validos.all.sum(&:numero_de_acessos).to_f * 100]
      end
    end
    percentuais
  end

  def cinco_maiores_percentuais_de_acessos_por_subarea
    percentuais = []
    unless @conteudos_validos.empty?
      SubArea.all.map(&:id).each do |subarea|
        percentuais << [@conteudos_validos.where("#{subarea} = sub_area_id").
                          sum(&:numero_de_acessos) /
                        @conteudos_validos.all.sum(&:numero_de_acessos).to_f * 100,
                        SubArea.find(subarea).nome]
      end
    end
    percentuais.sort.reverse[0..4]
  end

  def instituicoes_contribuidoras
    instituicoes_contribuidoras = []
    ids_instituicoes = @conteudos_validos.map(&:campus).map(&:instituicao_id)
    ids_instituicoes.uniq.each do |id|
      instituicoes_contribuidoras << [ids_instituicoes.count(id), Instituicao.find(id).nome]
    end
    instituicoes_contribuidoras.sort.reverse[0..4]
  end

  def campus_contribuidores
    contribuidores = []
    @conteudos_validos.all.map(&:campus_id).uniq.each do |id|
      contribuidores << [@conteudos_validos.where(campus_id: id).count, Campus.find(id).nome]
    end
    contribuidores.sort.reverse[0..4]
  end

  private

  def usuarios(data_inicial, data_final)
    Usuario.where('created_at between ? and ?', data_inicial, data_final).count
  end
end
