require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'


Spork.prefork do
  require 'rubygems'
  ENV["RAILS_ENV"] ||= 'test'

  # inicia simplecov (coverage) se não estiver usando spork, e com COVERAGE=true
  if !Spork.using_spork? && ENV["COVERAGE"]
    puts "Running Coverage Tool\n"
    require 'simplecov'
    require 'simplecov-rcov'
    SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
    SimpleCov.start 'rails'
  end

  require 'rails/application'
  # Use of https://github.com/sporkrb/spork/wiki/Spork.trap_method-Jujutsu
  Spork.trap_method(Rails::Application, :reload_routes!)
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)

  # As próximas etapas são para re-carregar app/models/..., app/controllers/... no spork
  # como visto em http://my.rails-royce.org/2012/01/14/reloading-models-in-rails-3-1-when-usign-spork-and-cache_classes-true/
  # Prevent main application to eager_load in the prefork block (do not load files in autoload_paths)
  # I.e., prevent Rails::Application to loads files in the application autoload_paths
  # such as app/models, app/controllers, etc.
  Spork.trap_method(Rails::Application, :eager_load!)
  # Depois dessa linha já é tarde demais. Now, load the rails stack
  require File.expand_path("../../config/environment", __FILE__)
  # Load all railties files, i.e., eager load all the engines
  Rails.application.railties.all { |r| r.eager_load! }

  require 'rspec/rails'
  require 'rspec/autorun'
  require 'capybara/rails'
  require 'capybara/poltergeist'
  require 'valid_attribute'
  require 'cancan/matchers'
  require 'rufus/scheduler'

  if Spork.using_spork?
    ## other requires to reduce (improve) test load-time
    # as test with script tooked from http://www.opinionatedprogrammer.com/2011/02/profiling-spork-for-faster-start-up-time/
    require 'rspec/core'
    require 'rspec/mocks'
    require 'rspec/expectations'
    require 'treetop/runtime'
  end

  unless ENV["INTEGRACAO"]
    require 'integration/fake_sam'
    require 'integration/fake_nsicloudooo'
  end

  # ver http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/
  #Devise.stretches = 1
  Rails.logger.level = 4

  # disable encryption of passwords in devise, let it be plain-text
  module Devise
    module Models
      module DatabaseAuthenticatable

        def valid_password?(password)
          return false if encrypted_password.blank?

          encrypted_password == password_digest(password)
        end

        protected

        def password_digest(password)
          password
        end
      end
    end
  end
  Devise.setup do |config|
    config.stretches = 0
  end

  class ActiveRecord::Base
    mattr_accessor :shared_connection
    @@shared_connection = nil

    def self.connection
      @@shared_connection || retrieve_connection
    end
  end

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}


  # flag counter to manually manipulate Garbage Collection in order to improve speed
  counter = -1
  RSpec.configure do |config|
    config.include Devise::TestHelpers, :type => :controller

    # testes de busca são dependentes do elasticsearch
    config.filter_run_excluding busca: true unless ENV['INTEGRACAO']

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # check phantomjs availability in order to use poltergeist driver on capybara
    def is_command_available command
      system("which #{command} > /dev/null 2>&1")
    end
    if is_command_available(:phantomjs)
      js_driver = :poltergeist
    else
      js_driver = :webkit
    end
    Capybara.javascript_driver = js_driver

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # manually manipulate Garbage Collection in order to improve test speed
    config.after(:each) do
      counter += 1
      if counter > 9
        GC.enable
        GC.start
        GC.disable
        counter = 0
      end
    end
    config.after(:suite) do
      counter = 0
    end
  end

  Tire.configure do
    unless ENV['INTEGRACAO']
      client Tire::Http::Client::MockClient
    end
  end
end

Spork.each_run do
  # manually manipulage GC in order to improve speed
  GC.disable

  # use an 'in-memory' SQLite database
  # and do not make noisy ouput to test output
  ActiveRecord::Schema.verbose = false
  load "#{Rails.root.to_s}/db/schema.rb"

  # Forces all threads to share the same connection. This works on
  # Capybara because it starts the web server in a thread.
  ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

  # This steps will only be runned when using spork
  if Spork.using_spork?
    FactoryGirl.reload
  end

end

