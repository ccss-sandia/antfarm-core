# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'rubygems'
require 'active_record'
require 'erb'
require 'yaml'

module Antfarm

  class Initializer
    attr_reader :configuration

    def self.run(command = :process, configuration = Configuration.new)
      yield configuration if block_given?
      initializer = new configuration
      initializer.send(command)
    end

    def initialize(configuration)
      @configuration = configuration
    end

    def process
      initialize_database
      initialize_logger
      load_requirements
    end

    def set_load_path
      load_paths = configuration.load_paths
      load_paths.reverse_each { |path| $LOAD_PATH.unshift(path) if File.directory?(path) }
      $LOAD_PATH.uniq!
    end

    #######
    private
    #######

    def initialize_database
      config = { ANTFARM_ENV => { 'adapter' => 'sqlite3', 'database' => db_file_to_use } }
      ActiveRecord::Base.configurations = config
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[ANTFARM_ENV])
    end

    def initialize_logger
      logger = Logger.new(log_file_to_use)
      logger.level = Logger.const_get(configuration.log_level.to_s.upcase)
      ActiveRecord::Base.logger = logger
    end

    def load_requirements
      require 'antfarm'
      require 'models'

#     Find.find(ANTFARM_ROOT + "/lib/models") do |path|
#       if File.file?(path) && path =~ /rb$/
#         require File.basename(path, ".*")
#       end
#     end
    end

    def db_file_to_use
      if defined? USER_DIR
        return File.expand_path("#{USER_DIR}/db/#{ANTFARM_ENV}.db")
      else
        return File.expand_path("#{ANTFARM_ROOT}/db/#{ANTFARM_ENV}.db")
      end
    end

    def log_file_to_use
      if defined? USER_DIR
        return File.expand_path("#{USER_DIR}/log/#{ANTFARM_ENV}.log")
      else
        return File.expand_path("#{ANTFARM_ROOT}/log/#{ANTFARM_ENV}.log")
      end
    end
  end

  class Configuration
    attr_accessor :load_paths
    attr_accessor :log_level
    
    def initialize
      self.load_paths = default_load_paths
      self.log_level = default_log_level
    end

    #######
    private
    #######

    def default_load_paths
      paths = Array.new

      paths << File.expand_path(ANTFARM_ROOT + "/lib")
      paths << File.expand_path(ANTFARM_ROOT + "/lib/models")
      paths << File.expand_path(ANTFARM_ROOT + "/lib/scripts")
      paths << File.expand_path(ANTFARM_ROOT + "/rails")

      return paths
    end

    def default_log_level
      return :warn
    end
  end

end

