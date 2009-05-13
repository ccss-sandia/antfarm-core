# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
#
# This script is modeled after the Rails initializer class.

# require 'logger'
require 'yaml'

require 'rubygems'
require 'dm-core'
# require 'sequel'

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

      # Make sure an application directory exists for the current user
      Antfarm::Helpers.create_user_directory
    end

    #######
    private
    #######

    def load_helpers
      require 'antfarm/helpers'
    end

    # Currently, SQLite3 and PostgreSQL databases are the only ones supported.
    # The name of the ANTFARM environment (which defaults to 'antfarm') is the
    # name used for the database file and the log file.
    def initialize_database
      config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))
#     if (defined? USER_DIR) && File.exists?("#{USER_DIR}/config/defaults.yml")
#       config = YAML::load(IO.read("#{USER_DIR}/config/defaults.yml"))
#     end
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
#     Sequel.connect("sqlite://#{config[ANTFARM_ENV]['database']}")
#     ActiveRecord::Base.configurations = config
#     ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[ANTFARM_ENV])
    end

    def initialize_logger
#     @logger = Logger.new(Antfarm::Helpers.log_file(ANTFARM_ENV))
#     @logger.level = Logger.const_get(configuration.log_level.to_s.upcase)
      @logger = DataMapper::Logger.new(Antfarm::Helpers.log_file(ANTFARM_ENV), configuration.log_level)
#     Sequel::DATABASES.first.logger = @logger
#     ActiveRecord::Base.logger = @logger
      Antfarm::Helpers.logger_callback = lambda do |severity,msg|
        @logger.send(severity,msg)
      end
    end
    
    def load_requirements
      require 'antfarm'
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
