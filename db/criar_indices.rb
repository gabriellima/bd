require "tire"
require "yaml"

es = defined?(Rails) ? Rails.application.config.elasticsearch_config : {}
es_host = es['host'] || 'localhost'
es_port = es['port'] || '9200'

Tire.configure do
  url "#{es_host}:#{es_port}"
end

properties = {
  :id               => {:type => 'string', :index => :not_analyzed},
  :arquivo_base64   => { :type => 'attachment'},
}

Tire.index 'conteudos' do
  delete
  create :mappings => {
    :artigo_de_evento => {
      :properties => properties
    },
    :artigo_de_periodico => {
      :properties => properties
    },
    :livro => {
      :properties => properties
    },
    :objeto_de_aprendizagem => {
      :properties => properties
    },
    :periodico_tecnico_cientifico => {
      :properties => properties
    },
    :relatorio => {
      :properties => properties
    },
    :trabalho_de_obtencao_de_grau => {
      :properties => properties
    }
  }
end