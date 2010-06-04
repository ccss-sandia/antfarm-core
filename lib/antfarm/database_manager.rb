require 'trollop'

module Antfarm
  class DatabaseManager
    def initialize(args = ARGV)
      options = parse_options(args)
      if options[:clean]
        db_clean { |m| puts m }
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

    # TODO <scrapcoder>: figure out how to DRY up logging and notification block/yield code

    # Removes the database and log files based on the ANTFARM environment given
    def db_clean
      message = "Deleting #{ANTFARM_ENV} log file..."
      Antfarm::Helpers.log :info, message
      yield message if block_given?

      FileUtils.rm "#{Antfarm::Helpers.log_file(ANTFARM_ENV)}" if File.exists?(Antfarm::Helpers.log_file(ANTFARM_ENV))

      message = "Deleted #{ANTFARM_ENV} log file successfully."
      Antfarm::Helpers.log :info, message
      yield message if block_given?

      config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))

      # TODO <scrapcoder>: can this stuff be done using the postgres gem instead?
      if config && config[ANTFARM_ENV] && config[ANTFARM_ENV]['adapter'] == 'postgres'
        message = "Dropping PostgreSQL #{ANTFARM_ENV} database..."
        Antfarm::Helpers.log :info, message
        yield message if block_given?

        exec "dropdb #{ANTFARM_ENV}"

        message = "Dropped PostgreSQL #{ANTFARM_ENV} database successfully."
        Antfarm::Helpers.log :info, message
        yield message if block_given?
      else
        message = "Dropping SQLite3 #{ANTFARM_ENV} database..."
        Antfarm::Helpers.log :info, message
        yield message if block_given?

        FileUtils.rm "#{Antfarm::Helpers.db_file(ANTFARM_ENV)}" if File.exists?(Antfarm::Helpers.db_file(ANTFARM_ENV))

        message = "Dropped SQLite3 #{ANTFARM_ENV} database successfully."
        Antfarm::Helpers.log :info, message
        yield message if block_given?
      end
    end

    # Creates a new database and schema file.  The location of the newly created
    # database file is set in the initializer class via the user
    # configuration hash, and is based on the current ANTFARM environment.
    def db_migrate
      begin
        message = 'Migrating database...'
        Antfarm::Helpers.log :info, message
        yield message if block_given?

        DataMapper.auto_upgrade!

        message = 'Database successfully migrated.'
        Antfarm::Helpers.log :info, message
        yield message if block_given?
      rescue => e # TODO: better error catching - not EVERY error is PostreSQL...
        yield e.message if block_given?

        message = "No PostgreSQL database exists for the #{ANTFARM_ENV} environment. Creating PostgreSQL database..."
        Antfarm::Helpers.log :info, message
        yield message if block_given?

        exec "createdb #{ANTFARM_ENV}"

        message = 'PostgreSQL database for this environment created. Continuing on with migration.'
        Antfarm::Helpers.log :info, message
        yield message if block_given?

        DataMapper.auto_upgrade!

        message = 'Database successfully migrated.'
        Antfarm::Helpers.log :info, message
        yield message if block_given?
      end
    end

    # Forces a destructive migration
    def db_reset
      db_clean   { |m| puts m }
      db_migrate { |m| puts m }
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
