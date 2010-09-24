################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

require 'yaml'

require 'rubygems'
require 'dm-core'

module Antfarm
  class Initializer
    attr_reader :configuration

    # Run the initializer, first making the configuration object available
    # to the user, then creating a new initializer object, then running the
    # given command.
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

    def setup
      # Set application load paths
      load_paths = configuration.load_paths
      load_paths.reverse_each { |path| $LOAD_PATH.unshift(path) if File.directory?(path) }
      $LOAD_PATH.uniq!

      # Load the Antfarm::Helpers module
      load_helpers

      # Load the general Antfarm error classes
      load_errors

      # Make sure an application directory exists for the current user
      Antfarm::Helpers.create_user_directory
    end

    #######
    private
    #######

    def load_helpers
      require 'antfarm/helpers'
    end

    def load_errors
      require 'antfarm/errors'
    end

    # Currently, SQLite3 and PostgreSQL databases are the only ones supported.
    # The name of the ANTFARM environment (which defaults to 'antfarm') is the
    # name used for the database file and the log file.
    def initialize_database
      config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))
      # Database setup based on adapter specified
      if config && config[ANTFARM_ENV] && config[ANTFARM_ENV].has_key?('adapter')
        if config[ANTFARM_ENV]['adapter'] == 'sqlite3'
          config[ANTFARM_ENV]['database'] = Antfarm::Helpers.db_file(ANTFARM_ENV)
        elsif config[ANTFARM_ENV]['adapter'] == 'postgres'
          config[ANTFARM_ENV]['database'] = ANTFARM_ENV
        else
          # If adapter specified isn't one of sqlite3 or postgresql,
          # default to SQLite3 database configuration.
          config = nil
        end
      else
        # If the current environment configuration doesn't specify a
        # database adapter, default to SQLite3 database configuration.
        config = nil
      end
      # Default to SQLite3 database configuration
      config ||= { ANTFARM_ENV => { 'adapter' => 'sqlite3', 'database' => Antfarm::Helpers.db_file(ANTFARM_ENV) } }
      if config[ANTFARM_ENV]['adapter'] == 'postgres'
        DataMapper.setup(:default, "postgres:///#{config[ANTFARM_ENV]['database']}")
      else
        DataMapper.setup(:default, "sqlite3://#{config[ANTFARM_ENV]['database']}")
      end
    end

    def initialize_logger
      @logger = DataMapper::Logger.new(Antfarm::Helpers.log_file(ANTFARM_ENV), configuration.log_level)
      Antfarm::Helpers.logger_callback = lambda do |severity,msg|
        @logger.send(severity,msg)
      end
    end
    
    def load_requirements
      # This will most likely already have been required by RubyGems, but let's
      # keep it in here anyway just in case...
      #
      # Note that 'antfarm-core' calls for boot strapping the ANTFARM
      # environment. However, that shouldn't lead to a circular dependency
      # here since this 'load_requirements' method is called by the initializer
      # 'process' method, not the boot strap's 'setup' method.
      require 'antfarm-core'
    end
  end

  class Configuration
    attr_accessor :load_paths
    attr_accessor :log_level
    
    def initialize
      self.load_paths = default_load_paths
      self.log_level  = default_log_level
    end

    #######
    private
    #######

    def default_load_paths
      paths  = Array.new
      paths << File.expand_path(ANTFARM_ROOT + "/lib")
      return paths
    end

    def default_log_level
      return :warn
    end
  end
end
