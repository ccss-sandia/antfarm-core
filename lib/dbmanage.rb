# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'erb'
require 'ostruct'
require 'yaml'

module Antfarm

  class DBManager < SCParse::Command
    def initialize
      super('db')

      @opts = OpenStruct.new
      @opts.adapter = "sqlite3"
      @opts.add_environment = false
      @opts.clean = false
      @opts.delete_environment = false
      @opts.drop = false
      @opts.environment = nil
      @opts.schema_load = false
      @opts.migrate = false
      @opts.reset = false
      @opts.version = nil

      @options = OptionParser.new do |opts|
        opts.on('--add_env ENV', "Add new Antfarm environment") do |env|
          @opts.add_environment = true
          @opts.environment = env
        end
#       opts.on('--clean', "Clean the application's database data") { @opts.clean = true }
#       opts.on('--adapter ADAPTER', "Database adapter to use (only useful when adding new Antfarm environment)") do |adapter|
#         @opts.db_adapter = adapter
#       end
#       opts.on('--del_env ENV', "Delete existing Antfarm environment") do |env|
#         @opts.delete_environment = true
#         @opts.environment = env
#       end
#       opts.on('--drop', "Drop tables in database") { @opts.drop = true }
        opts.on('--migrate [VERSION]', "Migrate tables in database (to the optional version)") do |version|
          @opts.migrate = true
          @opts.version = version
        end
#       opts.on('--reset', "Reset tables in database") { @opts.reset = true }
#       opts.on('--schema_load', "Load tables in database from schema") { @opts.schema_load = true }
      end
    end

    def execute(args)
      super(args)

      if @opts.add_environment
        add_environment
      elsif @opts.delete_environment
        delete_environment
      elsif @opts.clean
        db_clean
      elsif @opts.drop
        db_drop
      elsif @opts.migrate
        db_migrate(@opts.version)
      elsif @opts.reset
        db_reset
      elsif @opts.schema_load
        db_load
      end
    end

    #######
    private
    #######

    def add_environment
      if @opts.environment
        config = YAML::load(ERB.new(IO.read(File.expand_path(ANTFARM_ROOT + "/config/database.yml"))).result)

        temp = Hash.new
        temp['adapter'] = @opts.adapter
        temp['database'] = "db/#{@opts.environment}.db"
        config[@opts.environment] = temp

        File.open(File.expand_path(ANTFARM_ROOT + "/config/database.yml"), 'w') do |output|
          output.puts "# DO NOT DELETE THE 'antfarm' ENVIRONMENT"
          output.puts
          YAML::dump(config, output)
        end
      end
    end

    def delete_environment
      if @opts.environment
        config = YAML::load(ERB.new(IO.read(File.expand_path(ANTFARM_ROOT + "/config/database.yml"))).result)

        config.delete(@opts.environment)

        File.open(ANTFARM_ROOT + "/config/database.yml", 'w') do |output|
          output.puts "# DO NOT DELETE THE 'antfarm' ENVIRONMENT"
          output.puts
          YAML::dump(config, output)
        end
      end
    end

    def db_load
      if File.exists?(ANTFARM_ROOT + "/db/schema.rb")
        load(ANTFARM_ROOT + "/db/schema.rb")
      else
        puts "A schema file did not exist. Running migrations instead."
        db_migrate
      end
    end

    def db_drop
      config = YAML.load_file(ANTFARM_ROOT + "/config/database.yml")[ANTFARM_ENV]

      if File.exists?(ANTFARM_ROOT + "/" + config['database'])
        `rm #{ANTFARM_ROOT + "/" + config['database']}`
      else
        puts "The database #{config['database']} does not exist."
      end
    end

    def db_reset
      db_drop
      db_load
    end

    def db_migrate(version = nil)
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate(ANTFARM_ROOT + "/db/migrate/", version ? version.to_i : nil)
      db_schema_dump if ActiveRecord::Base.schema_format == :ruby
    end

    def db_schema_dump
      require 'active_record/schema_dumper'

      File.open(ANTFARM_ROOT + "/db/schema.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    def db_clean
      config = YAML.load_file(ANTFARM_ROOT + "/config/database.yml")
      config.each_pair do |key,value|
        `rm #{ANTFARM_ROOT}/log/#{key}.log` if File.exists?(ANTFARM_ROOT + "/log/#{key}.log")
        `rm #{ANTFARM_ROOT}/#{value['database']}` if File.exists?(ANTFARM_ROOT + "/#{value['database']}")
      end
      `rm #{ANTFARM_ROOT}/db/schema.rb` if File.exists?(ANTFARM_ROOT + "/db/schema.rb")
    end
  end

end
