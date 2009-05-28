require 'antfarm/console'
require 'antfarm/database_manager'
require 'antfarm/plugin'
require 'antfarm/ui'

module Antfarm
  class Framework
    attr_reader :plugin
    attr_reader :plugins

    # TODO <scrapcoder>: make it possible to only load a single plugin.
    # See if the plugin is already in the plugins hash, and if not,
    # load the single plugin.
    def plugins
      load_plugins if @plugins.nil?
      return @plugins
    end

    def db(args)
      Antfarm::DatabaseManager.new(args)
    end

    def console(opts = [])
      Antfarm::Console.new(opts)
    end

    def show
      table        = Antfarm::UI::Console::Table.new
      table.header = ['Plugin Name', 'Plugin Description']
      plugins.each do |name,plugin|
        table.add_row([name, plugin.info[:desc]])
      end
      table.print
    end

    def use(plugin)
      raise ArgumentError, 'Must supply name of one plugin to use' if plugin.nil? or plugin.empty?
      raise ArgumentError, "#{plugin} does not exist" unless plugins.has_key?(plugin)
      @plugin = plugins[plugin]
    end

    def back
      @plugin_name = nil
      @plugin      = nil
    end

    def run(options = Hash.new)
      raise ArgumentError, 'No plugin loaded' unless @plugin
      if @plugin.options.nil?
        @plugin.run
      else
        @plugin.run(options)
      end
    end

    def method_missing(method, *args)
      raise ArgumentError, "Command '#{method}' not recognized"
    end

    #######
    private
    #######

    # TODO <scrapcoder>: make it possible to load single plugin.
    def load_plugins
      @plugins = Hash.new
      # TODO <scrapcoder>: check for error raised when a plugin already exists.
      Antfarm::Plugin.load(:all) do |plugin|
        @plugins[plugin.name] = plugin
      end
    end
  end
end
