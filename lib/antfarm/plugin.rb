require 'find'

module Antfarm
  class PluginInheritanceError < RuntimeError; end

  class Plugin
    attr_accessor :name

    PLUGIN_ROOTS = ["#{ANTFARM_ROOT}/plugins"]
    PLUGIN_ROOTS << Antfarm::Helpers.user_plugins_dir

    def self.load(plugin)
      if plugin == :all
        PLUGIN_ROOTS.each do |root|
          # dive into the root directory to look for plugins
          Find.find("#{root}/") do |path|
            # don't operate on directories directly
            unless File.directory?(path)
              # only proceed if the file looks like a ruby file
              if File.file?(path) && path =~ /rb$/
                begin
                  # remove .rb from the end of the path
                  path.sub! /.rb/, ''
                  # the name of the plugin is the full file name (directories included)
                  # without everything up to and including the 'root plugins' directory
                  name = path.sub /^.*#{root}\//, ''
                  require path.untaint
                  # capitalize each of the directory names since they signify modules
                  # remove underscore and capitalize first letter after underscore
                  # taken from ActiveSupport's Inflector#camelize method
                  camelized_name = name.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
                  # create class object for plugin
                  plugin_class = eval("Antfarm::#{camelized_name}")
                  # make sure plugin inherits from this class
                  raise Antfarm::PluginInheritanceError unless plugin_class < self
                  # create a new plugin object
                  plugin = plugin_class.new
                  # tell the plugin what its name is
                  plugin.name = name
                  # send the plugin to the block
                  yield plugin
                rescue LoadError => err
                  puts "An error occurred while trying to load #{name} - this plugin will be unavailable"
                  Antfarm::Helpers.log :warn, err
                rescue Antfarm::PluginInheritanceError => err
                  puts "#{name} does not inherit from Antfarm::Plugin - this plugin will be unavailable"
                  Antfarm::Helpers.log :warn, err
                rescue Exception => err
                  puts "An error occurred while initializing #{name} - this plugin will be unavailable"
                  AntfarmHelpers.log :warn, err
                end
              end
            end
          end
        end
      end
    end

    def initialize
      @info             = Hash.new
      @options          = Hash.new
      @data_store       = Hash.new
      @required_options = Array.new
    end

    def register_info(info)
      info.each do |key,value|
        @info[key] = value
      end
    end

    def register_options(*opts)
      opts.each do |options|
        option              = options.delete(:name)
        @options[option]    = options
        @required_options << option if options[:required] == true
        @data_store[option] = options[:default] if options.has_key?(:default)
      end
      @required_options.uniq!
    end

    def description
      return @info[:description]
    end

    def show_info
      header = Array.new
      data   = Array.new
      @info.each do |key,value|
        header << key.to_s.capitalize
        data << value
      end
      table        = Antfarm::UI::Console::Table.new
      table.header = header
      table.add_row(data)
      table.print
    end

    def show_options
      table        = Antfarm::UI::Console::Table.new
      table.header = ['Name', 'Required', 'Current Setting', 'Description']
      @options.each do |name,info|
        current_setting = @data_store.has_key?(name) ? @data_store[name].to_s : 'N/A'
        table.add_row([name, info[:required].to_s, current_setting, info[:description]])
      end
      table.print
    end

    def set_option(option,value)
      return nil unless @options.has_key?(option)
      @data_store[option] = value
    end

    def unset_option(option)
      return @data_store.delete(option)
    end

    def check_required_options
      required_options_not_set = Array.new
      @required_options.each do |option|
        required_options_not_set << option unless @data_store.has_key?(option)
      end
      unless required_options_not_set.empty?
        puts 'Required options for this plugin have not yet been set'
        show_options
        return false
      end
      return true
    end
  end
end
