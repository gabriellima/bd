# encoding: utf-8

class PeriodicoTecnicoCientifico < Conteudo
  index_name 'conteudos'
  this_year = Date.today.year
  validates :ano_primeiro_volume,
    numericality: { greater_than: 0, less_than_or_equal_to: this_year,
                    allow_blank: true }
  validates :ano_ultimo_volume,
    numericality: { greater_than: 0, less_than_or_equal_to: this_year,
                    allow_blank: true }

  def nome_humanizado
    "Periódico técnico-científico"
  end
end
