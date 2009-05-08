require 'fileutils'
require 'postgres'

module Antfarm
  class DatabaseManager
    def initialize(args = ARGV)
      options = parse_options(args)
      if options[:clean]
        db_clean
      elsif options[:migrate]
        db_migrate
      elsif options[:reset]
        db_reset
      elsif options[:console]
        db_console
      end
    end

    #######
    private
    #######

    def parse_options(args)
      return Trollop::options(args) do
        banner <<-EOS

Antfarm Database Manager

Options:
        EOS
        opt :clean,   "Clean application's environment (REMOVE ALL!)"
        opt :migrate, 'Migrate tables in database'
        opt :reset,   'Reset tables in database and clear log file for given environment (clean + migrate)'
        opt :console, 'Start up relevant database console using database for given environment'
      end
    end

    # Removes the database and log files based on the ANTFARM environment given
    def db_clean
      FileUtils.rm "#{Antfarm::Helpers.log_file(ANTFARM_ENV)}" if File.exists?(Antfarm::Helpers.log_file(ANTFARM_ENV))
      FileUtils.rm "#{Antfarm::Helpers.db_file(ANTFARM_ENV)}"  if File.exists?(Antfarm::Helpers.db_file(ANTFARM_ENV))
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
        exec "sqlite3 #{Antfarm::Helpers.db_file(ANTFARM_ENV)}"
      end
    end
  end
end
