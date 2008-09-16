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

require 'rubygems'
require 'active_record'

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
      load_requirements
      initialize_database
      initialize_logger
    end

    def set_load_path
      load_paths = configuration.load_paths
      load_paths.reverse_each { |path| $LOAD_PATH.unshift(path) if File.directory?(path) }
      $LOAD_PATH.uniq!
    end

    #######
    private
    #######

    def load_requirements
      require 'antfarm'
    end

    # Currently, sqlite3 databases are the only ones supported. The name of the ANTFARM environment
    # (which defaults to 'antfarm') is the name used for the database file and the log file.
    def initialize_database
      config = { ANTFARM_ENV => { 'adapter' => 'sqlite3', 'database' => Antfarm.db_file_to_use } }
      ActiveRecord::Base.configurations = config
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[ANTFARM_ENV])
    end

    def initialize_logger
      logger = Logger.new(Antfarm.log_file_to_use)
      logger.level = Logger.const_get(configuration.log_level.to_s.upcase)
      ActiveRecord::Base.logger = logger
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
      paths << File.expand_path(ANTFARM_ROOT + "/lib/scripts")
      paths << File.expand_path(ANTFARM_ROOT + "/rails")

      return paths
    end

    def default_log_level
      return :warn
    end
  end

end
