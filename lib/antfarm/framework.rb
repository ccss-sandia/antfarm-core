require 'antfarm/plugin'

module Antfarm
  class Framework
    attr_reader :plugin

    # If this method is called first, ALL plugins will be
    # loaded and cached for the duration of process.
    def plugins
      return @plugins ||= Antfarm::Plugin.load
    end

    def clean_db
      message = "Deleting #{ANTFARM_ENV} log file..."
      Antfarm::Helpers.output message
      Antfarm::Helpers.log :info, message

      FileUtils.rm "#{Antfarm::Helpers.log_file(ANTFARM_ENV)}" if File.exists?(Antfarm::Helpers.log_file(ANTFARM_ENV))

      message = "Deleted #{ANTFARM_ENV} log file successfully."
      Antfarm::Helpers.output message
      Antfarm::Helpers.log :info, message

      config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))

      # TODO <scrapcoder>: can this stuff be done using the postgres gem instead?
      if config && config[ANTFARM_ENV] && config[ANTFARM_ENV]['adapter'] == 'postgres'
        message = "Dropping PostgreSQL #{ANTFARM_ENV} database..."
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message

        exec "dropdb #{ANTFARM_ENV}"

        message = "Dropped PostgreSQL #{ANTFARM_ENV} database successfully."
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message
      else
        message = "Dropping SQLite3 #{ANTFARM_ENV} database..."
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message

        FileUtils.rm "#{Antfarm::Helpers.db_file(ANTFARM_ENV)}" if File.exists?(Antfarm::Helpers.db_file(ANTFARM_ENV))

        message = "Dropped SQLite3 #{ANTFARM_ENV} database successfully."
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message
      end
    end

    # Creates a new database and schema file.  The location of the newly created
    # database file is set in the initializer class via the user
    # configuration hash, and is based on the current ANTFARM environment.
    def migrate_db
      begin
        message = 'Migrating database...'
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message

        DataMapper.auto_upgrade!

        message = 'Database successfully migrated.'
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message
      rescue => e # TODO: better error catching - not EVERY error is PostreSQL...
        message = "No PostgreSQL database exists for the #{ANTFARM_ENV} environment. Creating PostgreSQL database..."
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message

        exec "createdb #{ANTFARM_ENV}"

        message = 'PostgreSQL database for this environment created. Continuing on with migration.'
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message

        DataMapper.auto_upgrade!

        message = 'Database successfully migrated.'
        Antfarm::Helpers.output message
        Antfarm::Helpers.log :info, message
      end
    end

    # Forces a destructive migration
    def reset_db
      clean_db
      migrate_db
    end

    def use(plugin)
      @plugin = load_plugin(plugin)
    end

    def back
      @plugin_name = nil
      @plugin      = nil
    end

    def run(options = Hash.new)
      raise Antfarm::AntfarmError, 'No plugin loaded' unless @plugin

      if @plugin.options.nil?
        @plugin.run
      else
        @plugin.run(options)
      end
    end

    def method_missing(method, *args)
      raise Antfarm::AntfarmError, "Command '#{method}' not recognized"
    end

    #######
    private
    #######

    def load_plugin(plugin)
      raise Antfarm::AntfarmError, 'Must supply name of one plugin to use' if plugin.nil? or plugin.empty?

      @plugins ||= Hash.new
      return @plugins[plugin] if @plugins.has_key?(plugin)

      # Load and save the plugin. An exception will be
      # thrown if the plugin cannot be found or loaded.
      @plugins[plugin] = Antfarm::Plugin.load(plugin)

      # will not get here if plugin doesn't exist.
      # Exception will have been thrown by now.
      return @plugins[plugin]
    end
  end
end
