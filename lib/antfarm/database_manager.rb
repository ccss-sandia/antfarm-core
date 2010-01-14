require 'fileutils'

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
      args << '-h' if args.empty?

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

    # TODO <scrapcoder>: all these 'puts' statements need to be logged rather than printed, just in case
    # the command line interface isn't the one using the framework.

    # Removes the database and log files based on the ANTFARM environment given
    def db_clean
      FileUtils.rm "#{Antfarm::Helpers.log_file(ANTFARM_ENV)}" if File.exists?(Antfarm::Helpers.log_file(ANTFARM_ENV))
      config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))
      if config && config[ANTFARM_ENV] && config[ANTFARM_ENV]['adapter'] == 'postgres'
        # TODO <scrapcoder>: can this stuff be done using the postgres gem instead?
        puts "Dropping PostgreSQL #{ANTFARM_ENV} database..."
        `dropdb #{ANTFARM_ENV}`
        puts "Dropped PostgreSQL #{ANTFARM_ENV} database successfully."
      else
        FileUtils.rm "#{Antfarm::Helpers.db_file(ANTFARM_ENV)}"  if File.exists?(Antfarm::Helpers.db_file(ANTFARM_ENV))
      end
    end

    # Creates a new database and schema file.  The location of the newly created
    # database file is set in the initializer class via the user
    # configuration hash, and is based on the current ANTFARM environment.
    def db_migrate
      begin
        puts "Migrating database"
        DataMapper.auto_upgrade!
        puts "Database successfully migrated."
      rescue => e
        puts e.class
        puts "No PostgreSQL database exists for the #{ANTFARM_ENV} environment. Creating PostgreSQL database..."
        `createdb #{ANTFARM_ENV}`
        puts "PostgreSQL database for this environment created. Continuing on with migration."
        DataMapper.auto_upgrade!
        puts "Database successfully migrated."
      end
    end

    # Forces a destructive migration
    def db_reset
      db_clean
      db_migrate
    end

    def db_console
      config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))
      puts "Loading #{ANTFARM_ENV} environment"
      if config && config[ANTFARM_ENV] && config[ANTFARM_ENV]['adapter'] == 'postgres'
        exec "psql #{ANTFARM_ENV}"
      else
        exec "sqlite3 #{Antfarm::Helpers.db_file(ANTFARM_ENV)}"
      end
    end
  end
end
