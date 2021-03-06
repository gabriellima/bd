require 'spec_helper'

describe Usuario do
  describe 'abilities' do
    subject { ability }
    let(:ability) { Ability.new(usuario) }
    let(:tipos) do
      [ArtigoDeEvento, ArtigoDePeriodico, Livro,
       ObjetoDeAprendizagem, PeriodicoTecnicoCientifico,
       Relatorio, TrabalhoDeObtencaoDeGrau]
    end

    before(:each) do
      Factory.create(:papel_gestor)
      Factory.create(:papel_contribuidor)
      Factory.create(:papel_admin)
    end

    shared_examples 'adicionar e ler todos os tipos de conteudo' do
      it 'pode adicionar todos os tipos de conteudo' do
        tipos.each do |conteudo|
          should be_able_to(:create, conteudo)
        end
      end

      it 'pode acessar todos os tipos de conteudo' do
        tipos.each do |conteudo|
          should be_able_to(:read, conteudo)
        end
      end
    end

    context 'contribuidor de conteudo' do
      let(:usuario) { Factory.create(:usuario_contribuidor) }

      include_examples 'adicionar e ler todos os tipos de conteudo'
    end
  end

  context 'escrivaninha' do
    it 'retorna os conteudos do usuario que sao editaveis' do
      usuario = Usuario.new
      Conteudo.should_receive(:pendentes).with(usuario).and_return('pendentes')
      Conteudo.should_receive(:editaveis).with(usuario).and_return('editaveis')
      usuario.escrivaninha.should == 'editaveispendentes'
    end
  end

  context 'estante' do
    it 'retorna os conteudos aprovados do usuario' do
      usuario = Usuario.new
      Conteudo.should_receive(:publicados).with(usuario).and_return([:publicados])
      usuario.should_receive(:graos_favoritos).and_return([:graos_favoritos])
      usuario.should_receive(:conteudos_favoritos).and_return([:conteudos_favoritos])
      usuario.estante.should == [:publicados, :graos_favoritos, :conteudos_favoritos]
    end
  end

  it { should have_valid(:email).when 'bernardo.fire@gmail.com', 'aeiou@abcd.com' }
  it { should_not have_valid(:email).when '', nil }

  it { should have_valid(:nome_completo).when 'Luke Skywalker', 'Darth Vader', 'foo 123' }
  it { should_not have_valid(:nome_completo).when nil, '' }

  it 'responde se possui um determinado papel' do
    usuario = Usuario.new
    papeis = ['gestor', 'admin', 'contribuidor'].map {|nome|
      Papel.create!(nome: nome, descricao: 'dummy')
    }
    usuario.papeis = papeis[0..1]
    usuario.should be_gestor
    usuario.should be_admin
    usuario.should_not be_contribuidor
    expect { usuario.qqcoisa? }.to raise_error(NoMethodError)
  end

  context 'cesta' do
    let(:usuario) { Factory.create(:usuario) }

    it 'permite adicionar graos' do
      usuario.cesta << stub_model(Grao)
      usuario.cesta << stub_model(Grao)
      usuario.cesta.should have(2).graos
    end
  end
end
