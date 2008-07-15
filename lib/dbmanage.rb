# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'fileutils'

module Antfarm

  # Extends SCParse::Command so it can be considered as a command.
  class DBManager < SCParse::Command
    def initialize
      # set the command name to 'db'
      super('db')

      @opts = OpenStruct.new
      @opts.clean = false
      @opts.initialize = false
      @opts.migrate = false
      @opts.remove = false
      @opts.reset = false

      @options = OptionParser.new do |opts|
        opts.on('--initialize', "Initialize user's environment") do
          @opts.initialize = true
        end
        opts.on('--clean', "Clean the application's environment (remove all)") { @opts.clean = true }
        opts.on('--remove', "Remove existing database and log file for the given environment") do
          @opts.remove = true
        end
        opts.on('--migrate', "Migrate tables in database") do
          @opts.migrate = true
        end
        opts.on('--reset', "Reset tables in database and clear the log file for the given environment") { @opts.reset = true }
      end
    end

    def execute(args)
      super(args)

      if @opts.initialize
        init
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

    # Initializes a suitable directory structure for the user
    def init
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/db")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/log")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/scripts")
    end

    # Removes the database based on the ANTFARM environment given
    def db_remove
      `rm #{Antfarm.log_file_to_use}` if File.exists?(Antfarm.log_file_to_use)
      `rm #{Antfarm.db_file_to_use}` if File.exists?(Antfarm.db_file_to_use)
    end

    # Removes any database, schema, and log files found
    def db_clean
      Find.find(Antfarm.db_dir_to_use) do |path|
        if File.basename(path) == 'migrate'
          Find.prune
        else
          `rm #{path}` unless File.basename(path) == 'db' || File.basename(path) == 'schema.rb'
        end
      end

      Find.find(Antfarm.log_dir_to_use) do |path|
        `rm #{path}` unless File.basename(path) == 'log'
      end
    end

    # Creates a new database and schema file.  The location of the newly created
    # database file is set in the initializer class via the ActiveRecord 
    # configuration hash, and is based on the current ANTFARM environment.
    def db_migrate
      if File.exists?(File.expand_path("#{ANTFARM_ROOT}/db/schema.rb"))
        load(File.expand_path("#{ANTFARM_ROOT}/db/schema.rb"))
      else
        puts "A schema file did not exist. Running migrations instead."

        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate(ANTFARM_ROOT + "/db/migrate/", nil)
        db_schema_dump if ActiveRecord::Base.schema_format == :ruby
      end
    end

    def db_reset
      db_remove
      db_migrate
    end

    def db_schema_dump
      require 'active_record/schema_dumper'

      File.open(File.expand_path("#{ANTFARM_ROOT}/db/schema.rb"), "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end

end
