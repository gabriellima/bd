# encoding: utf-8

class TrabalhoDeObtencaoDeGrau < Conteudo
  index_name 'conteudos'
  belongs_to :grau
  validates :numero_paginas, numericality: { greater_than: 0, allow_blank:true }
  flexible_date :data_defesa, suffix: 'br'

  def nome_humanizado
    "Trabalho de obtenção de grau"
  end
end
