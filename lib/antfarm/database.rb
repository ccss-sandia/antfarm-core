# all the database models use validation
require 'dm-validations'

# require all the database models
require 'antfarm/database/ethernet_interface'
require 'antfarm/database/ip_interface'
require 'antfarm/database/ip_network'
require 'antfarm/database/layer2_interface'
require 'antfarm/database/layer3_interface'
require 'antfarm/database/layer3_network'
require 'antfarm/database/node'
require 'antfarm/database/private_network'
require 'antfarm/database/traffic'
require 'antfarm/database/dns_entry'
require 'antfarm/database/action'
require 'antfarm/database/service'
require 'antfarm/database/operating_system'

# requirements for the database manager
require 'fileutils'
require 'optparse'
require 'ostruct'
require 'postgres'

module Antfarm
  class DatabaseManager
    def initialize
      @opts = ::OpenStruct.new
      @opts.clean = false
      @opts.migrate = false
      @opts.reset = false
      @opts.console = false

      @options = ::OptionParser.new do |opts|
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
        opts.on('--console', "Start up an SQLite3 console using the database for the given environment") { @opts.console = true }
      end
    end

    def execute(args)
      @options.parse(args)

      if @opts.clean
        db_clean
      elsif @opts.migrate
        db_migrate
      elsif @opts.reset
        db_reset
      elsif @opts.console
        db_console
      end
    end

    #######
    private
    #######

    # Removes the database and log files based on the ANTFARM environment given
    def db_clean
      FileUtils.rm "#{Antfarm.log_file_to_use}" if File.exists?(Antfarm.log_file_to_use)
      FileUtils.rm "#{Antfarm.db_file_to_use}"  if File.exists?(Antfarm.db_file_to_use)
    end

    # Creates a new database and schema file.  The location of the newly created
    # database file is set in the initializer class via the user
    # configuration hash, and is based on the current ANTFARM environment.
    def db_migrate
      begin
        DataMapper.auto_upgrade!
      rescue ::PGError
        puts "Looks like you are using the PostgreSQL database and you haven't yet created a database for this environment."
        puts "Please execute 'psql #{ANTFARM_ENV}' to create the database, then try running 'antfarm db --migrate' again."
      end
    end

    # Forces a destructive migration
    def db_reset
      db_clean
      db_migrate
    end

    def db_console
      if (defined? USER_DIR) && File.exists?("#{USER_DIR}/config/defaults.yml")
        config = YAML::load(IO.read("#{USER_DIR}/config/defaults.yml"))
      end
      puts "Loading #{ANTFARM_ENV} environment"
      if config && config[ANTFARM_ENV] && config[ANTFARM_ENV]['adapter'] == 'postgresql'
        exec "psql #{ANTFARM_ENV}"
      else
        exec "sqlite3 #{Antfarm.db_file_to_use}"
      end
    end
  end
end
