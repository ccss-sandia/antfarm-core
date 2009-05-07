require 'antfarm/plugin'
require 'antfarm/ui'

module Antfarm
  class Framework
    attr_reader :plugin
    attr_reader :plugins

    def load_plugins
      @plugins = Hash.new
      Antfarm::Plugin.load(:all) do |plugin|
        @plugins[plugin.name] = plugin
      end
    end

    def db(args)
      Antfarm::DatabaseManager.new.execute(args)
    end

    def show
      table           = Antfarm::UI::Console::Table.new
      table.header    = ['Plugin Name', 'Plugin Description']
      @plugins.each do |name,plugin|
        table.add_row([name, plugin.description])
      end
      table.print
    end

    def use(args)
      raise ArgumentError, 'Must supply name of one plugin to use' unless args.length == 1
      name = args[0]
      raise ArgumentError, "#{name} does not exist" unless @plugins.has_key?(name)
      @plugin = @plugins[name]
    end

    def back
      @plugin_name = nil
      @plugin = nil
    end

    def info
      raise ArgumentError, 'No plugin loaded' unless @plugin
      @plugin.show_info
    end

    def options
      raise ArgumentError, 'No plugin loaded' unless @plugin
      @plugin.show_options
    end

    def set(args)
      raise ArgumentError, 'No option=value pairs to set were specified' if args.empty?
      args.each do |pair|
        option,value = pair.split('=')
        puts "#{option} is not used by this plugin" if @plugin.set_option(option,value).nil?
      end
    end

    def unset(args)
      raise ArgumentError, 'No options to unset were specified' if args.empty?
      args.each do |option|
        puts "#{option} is not currently set in this plugin" if @plugin.unset_option(option).nil?
      end
    end

    def run
      raise ArgumentError, 'No plugin loaded' unless @plugin
      @plugin.run if @plugin.check_required_options
    end

    def method_missing(method, *args)
      raise ArgumentError, "Command '#{method}' not recognized"
    end
  end
end
