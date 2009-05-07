require 'antfarm/ui'
require 'find'

module Antfarm
  class PluginExistanceError < RuntimeError; end
  class PluginInheritanceError < RuntimeError; end
  class PluginOptionsError < RuntimeError; end

  class Plugin
    attr_accessor :name

    PLUGIN_ROOTS  = ["#{ANTFARM_ROOT}/plugins"]
    PLUGIN_ROOTS << Antfarm::Helpers.user_plugins_dir

    # perform a quick discovery of plugins that exist
    def self.discover
      PLUGIN_ROOTS.each do |root|
        Find.find("#{root}/") do |path|
          unless File.directory?(path)
            if File.file?(path) && path =~ /rb$/
              path.sub! /.rb/, ''
              yield path.sub /^.*#{root}\//, ''
            end
          end
        end
      end
    end

    def self.load(plugin = :all)
      if plugin == :all
        PLUGIN_ROOTS.each do |root|
          # dive into the root directory to look for plugins
          Find.find("#{root}/") do |path|
            # don't operate on directories directly
            unless File.directory?(path)
              # only proceed if the file looks like a ruby file
              if path =~ /rb$/ and File.file?(path)
                instance = self.load_single_plugin(path, root)
                yield instance unless instance.nil?
              end
            end
          end
        end
      else
        begin
          #TODO <scrapcoder>: is there a better way to do this?!
          found = false
          PLUGIN_ROOTS.each do |root|
            path = "#{root}/#{plugin}.rb"
            if File.file?(path)
              found = true
              instance = self.load_single_plugin(path, root)
              unless instance.nil?
                yield instance
                break
              end
            end
          end
          raise Antfarm::PluginExistanceError unless found
        rescue Antfarm::PluginExistanceError => err
          puts "The plugin '#{plugin}' cannot be found."
          Antfarm::Helpers.log :warn, err
        rescue Exception => err
          puts "I dunno... #{err}"
        end
      end
    end

    def self.load_single_plugin(path, root)
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
        # return the plugin
        return plugin
      rescue LoadError => err
        puts "An error occurred while trying to load #{name} - this plugin will be unavailable"
        Antfarm::Helpers.log :warn, err
        return nil
      rescue Antfarm::PluginInheritanceError => err
        puts "#{name} does not inherit from Antfarm::Plugin - this plugin will be unavailable"
        Antfarm::Helpers.log :warn, err
        return nil
      rescue Exception => err
        puts "An error occurred while initializing #{name} - this plugin will be unavailable"
        Antfarm::Helpers.log :warn, err
        return nil
      end
    end

    ALLOWED_INFO    = [:name, :author, :desc ]
    ALLOWED_OPTIONS = [:name, :desc, :long, :short, :type, :default, :required]

    attr_reader :options

    def initialize(info = nil, options = nil)
      @info    = info
      @options = [options].flatten

      if @info
        @info.reject! { |k,v| !ALLOWED_INFO.include?(k) }
      end

      if @options
        for option in @options
          raise Antfarm::PluginOptionsError, 'Each option must specify a name' unless option[:name]
          raise Antfarm::PluginOptionsError, 'Each option must specify a description' unless option[:desc]
          option.reject! { |k,v| !ALLOWED_OPTIONS.include?(k) }
        end
      end
    end

    def show_info
      table        = Antfarm::UI::Console::Table.new
      table.header = ['Plugin Info', '']
      for key in ALLOWED_INFO
        table.add_row([key.to_s.capitalize, @info[key].to_s])
      end
      table.print
    end

    def show_options
      table        = Antfarm::UI::Console::Table.new
      table.header = ALLOWED_OPTIONS.map { |key| key.to_s.capitalize }
      for option in @options
        row = ALLOWED_OPTIONS.map { |key| option[key].to_s }
        table.add_row(row)
      end
      table.print
    end
  end
end
