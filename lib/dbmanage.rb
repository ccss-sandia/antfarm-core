# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'fileutils'

module Antfarm

  class DBManager < SCParse::Command
    def initialize
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

    def init
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/db")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/log")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/scripts")
    end

    def db_remove
      `rm #{log_file_to_use}` if File.exists?(log_file_to_use)
      `rm #{db_file_to_use}` if File.exists?(db_file_to_use)
    end

    def db_clean
      Find.find(db_dir_to_use) do |path|
        if File.basename(path) == 'migrate'
          Find.prune
        else
          `rm #{path}` unless File.basename(path) == 'db' || File.basename(path) == 'schema.rb'
        end
      end

      Find.find(log_dir_to_use) do |path|
        `rm #{path}` unless File.basename(path) == 'log'
      end
    end

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

    def db_file_to_use
      if defined? USER_DIR
        return File.expand_path("#{USER_DIR}/db/#{ANTFARM_ENV}.db")
      else
        return File.expand_path("#{ANTFARM_ROOT}/db/#{ANTFARM_ENV}.db")
      end
    end

    def db_dir_to_use
      if defined? USER_DIR
        return File.expand_path("#{USER_DIR}/db")
      else
        return File.expand_path("#{ANTFARM_ROOT}/db")
      end
    end

    def log_file_to_use
      if defined? USER_DIR
        return File.expand_path("#{USER_DIR}/log/#{ANTFARM_ENV}.log")
      else
        return File.expand_path("#{ANTFARM_ROOT}/log/#{ANTFARM_ENV}.log")
      end
    end

    def log_dir_to_use
      if defined? USER_DIR
        return File.expand_path("#{USER_DIR}/log")
      else
        return File.expand_path("#{ANTFARM_ROOT}/log")
      end
    end
  end

end

