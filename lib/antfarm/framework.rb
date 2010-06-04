require 'antfarm-plugins'

require 'antfarm/database_manager'
require 'antfarm-plugins'

module Antfarm
  class Framework
    attr_reader :plugin

    # If this method is called first, ALL plugins will be
    # loaded and cached for the duration of process.
    def plugins
      return @plugins ||= Antfarm::Plugin.load
    end

    def db(args)
      Antfarm::DatabaseManager.new(args)
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
