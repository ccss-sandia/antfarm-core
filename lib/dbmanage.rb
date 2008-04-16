# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

module Antfarm

  class DBManager < SCParse::Command
    def initialize
      super('db')

      @opts = OpenStruct.new
      @opts.adapter = "sqlite3"
      @opts.add = false
      @opts.clean = false
      @opts.environment = nil
      @opts.migrate = false
      @opts.remove = false
      @opts.reset = false

      @options = OptionParser.new do |opts|
        opts.on('--add ENV', "Add new database for the given environment") do |env|
          @opts.add = true
          @opts.environment = env
        end
#       opts.on('--clean', "Clean the application's environment") { @opts.clean = true }
#       opts.on('--adapter ADAPTER', "Database adapter to use (only useful when adding new Antfarm environment)") do |adapter|
#         @opts.db_adapter = adapter
#       end
#       opts.on('--remove ENV', "Remove existing database for the given environment") do |env|
#         @opts.remove = true
#         @opts.environment = env
#       end
        opts.on('--migrate', "Migrate tables in database") do |version|
          @opts.migrate = true
        end
#       opts.on('--reset', "Reset tables in database") { @opts.reset = true }
      end
    end

    def execute(args)
      super(args)

      if @opts.add
        db_add
      elsif @opts.remove
        db_remove
      elsif @opts.clean
        db_clean
      elsif @opts.migrate
        db_migrate
      elsif @opts.reset
        db_reset
      end
    end

    #######
    private
    #######

    def db_add
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

    def db_remove
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

    def db_clean
      config = YAML.load_file(ANTFARM_ROOT + "/config/database.yml")
      config.each_pair do |key,value|
        `rm #{ANTFARM_ROOT}/log/#{key}.log` if File.exists?(ANTFARM_ROOT + "/log/#{key}.log")
        `rm #{ANTFARM_ROOT}/#{value['database']}` if File.exists?(ANTFARM_ROOT + "/#{value['database']}")
      end
      `rm #{ANTFARM_ROOT}/db/schema.rb` if File.exists?(ANTFARM_ROOT + "/db/schema.rb")
    end

    def db_migrate(version = nil)
      if File.exists?(ANTFARM_ROOT + "/db/schema.rb")
        load(ANTFARM_ROOT + "/db/schema.rb")
      else
        puts "A schema file did not exist. Running migrations instead."

        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate(ANTFARM_ROOT + "/db/migrate/", version ? version.to_i : nil)
        db_schema_dump if ActiveRecord::Base.schema_format == :ruby
      end
    end

    def db_reset
      db_drop
      db_migrate
    end

    def db_drop
      config = YAML.load_file(ANTFARM_ROOT + "/config/database.yml")[ANTFARM_ENV]

      if File.exists?(ANTFARM_ROOT + "/" + config['database'])
        `rm #{ANTFARM_ROOT + "/" + config['database']}`
      else
        puts "The database #{config['database']} does not exist."
      end
    end

    def db_schema_dump
      require 'active_record/schema_dumper'

      File.open(ANTFARM_ROOT + "/db/schema.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end

end

