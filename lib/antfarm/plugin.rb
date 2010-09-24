require 'find'

module Antfarm
  class PluginExistanceError   < Antfarm::AntfarmError; end
  class PluginInheritanceError < Antfarm::AntfarmError; end
  class PluginOptionsError     < Antfarm::AntfarmError; end

  module Plugin
    attr_accessor :name

    PLUGIN_ROOTS  = ["#{File.dirname(__FILE__)}/plugins"]
    PLUGIN_ROOTS << Antfarm::Helpers.user_plugins_dir

    # perform a quick discovery of plugins that exist
    # TODO <scrapcoder>: add 'custom/' to the front of
    # plugins that don't originate in the 'root plugins'
    # directory.
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

    def self.load(plugin = nil)
      if plugin.nil? # load them all!
        plugins = Hash.new

        PLUGIN_ROOTS.each do |root|
          # dive into the root directory to look for plugins
          Find.find("#{root}/") do |path|
            # don't operate on directories directly
            unless File.directory?(path)
              # only proceed if the file looks like a ruby file
              if path =~ /rb$/ and File.file?(path)
                instance = self.load_single_plugin(path, root)
                plugins[instance.name] = instance unless instance.nil?
              end
            end
          end
        end

        return plugins
      else
        begin
          found = false

          PLUGIN_ROOTS.each do |root|
            path = "#{root}/#{plugin}.rb"

            if File.file?(path)
              instance = self.load_single_plugin(path, root)
              return instance unless instance.nil?
            end
          end

          # If we get here, a plugin was never
          # loaded and returned.
          raise Antfarm::PluginExistanceError, message
        rescue Exception => e
          raise Antfarm::AntfarmError, e.message
        end
      end
    end

    # TODO <scrapcoder>: check to see if module is already defined.
    # If so, raise an error, passing the name of the created plugin
    # object so a note can be presented to the user with the name/author
    # of the plugin already created.
    def self.load_single_plugin(path, root)
      begin
        # remove .rb from the end of the path
        path.sub! /.rb/, ''
        # the name of the plugin is the full file name (directories included)
        # without everything up to and including the 'root plugins' directory
        #
        # NOTE at this point name now == plugin variable passed to 'load()'
        name = path.sub /^.*#{root}\//, ''
        require path.untaint
        # capitalize each of the directory names since they signify modules
        # remove underscore and capitalize first letter after underscore/hyphen
        # taken from ActiveSupport's Inflector#camelize method
        camelized_name = name.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_|-)(.)/) { $2.upcase }
        # create class object for plugin
        plugin_class = eval("Antfarm::Plugin::#{camelized_name}")
        # make sure plugin inherits from this class
        unless plugin_class < self
          raise Antfarm::PluginInheritanceError, "#{name} does not inherit from Antfarm::Plugin - this plugin will be unavailable"
          return nil
        end
        # create a new plugin object
        plugin = plugin_class.new
        # tell the plugin what its name is
        plugin.name = name
        # return the plugin
        return plugin
      rescue LoadError
        raise Antfarm::AntfarmError, "An error occurred while trying to load #{name} - this plugin will be unavailable"
        return nil
      rescue Exception => ex
        Antfarm::Helpers.log :error, ex.message
        raise Antfarm::AntfarmError, "An error occurred while initializing #{name} - this plugin will be unavailable"
        return nil
      end
    end

    ALLOWED_INFO    = [:name, :author, :desc ]
    ALLOWED_OPTIONS = [:name, :desc, :long, :short, :type, :default, :required]

    attr_reader :info
    attr_reader :options

    def initialize(info = nil, options = nil)
      @info    = info
      @options = [options].flatten

      if @info
        @info.reject! { |k,v| !ALLOWED_INFO.include?(k) }
      end

      if @options
        for option in @options
          raise Antfarm::PluginOptionsError, 'Each option must specify a name'        unless option[:name]
          raise Antfarm::PluginOptionsError, 'Each option must specify a description' unless option[:desc]
          option.reject! { |k,v| !ALLOWED_OPTIONS.include?(k) }
          option[:type]    = :flag unless option.key?(:type)
          option[:default] = false if option[:type] == :flag
        end
      end
    end

    def print_message(message)
      Antfarm::Helpers.output "Message: #{message}"
    end

    def print_error(message)
      Antfarm::Helpers.output "Error: #{message}"
    end
  end
end
