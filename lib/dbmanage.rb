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

require 'fileutils'

module Antfarm

  # Extends SCParse::Command so it can be considered as a command.
  class DBManager < SCParse::Command
    def initialize
      # set the command name to 'db'
      super('db')

      @opts = OpenStruct.new
      @opts.clean = false
      @opts.initialize = false
      @opts.migrate = false
      @opts.remove = false
      @opts.reset = false
      @opts.console = false

      @options = OptionParser.new do |opts|
        opts.on('--initialize', "Initialize user's environment") do
          @opts.initialize = true
        end
        opts.on('--clean', "Clean the application's environment (remove all)") { @opts.clean = true }
        opts.on('--remove', "Remove existing database and log file for the given environment") do
          @opts.remove = true
        end
        opts.on('--migrate', "Migrate tables in database") do
          @opts.migrate = true
        end
        opts.on('--reset', "Reset tables in database and clear the log file for the given environment") { @opts.reset = true }
        opts.on('--console', "Start up an SQLite3 console using the database for the given environment") { @opts.console = true }
      end
    end

    def execute(args)
      super(args)

      if @opts.initialize
        init
      elsif @opts.remove
        db_remove
      elsif @opts.clean
        db_clean
      elsif @opts.migrate
        db_migrate
      elsif @opts.reset
        db_reset
      elsif @opts.console
        db_console
      end
    end

    #######
    private
    #######

    # Initializes a suitable directory structure for the user and
    # copies a default colors.xml file to the user's config directory
    def init
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/config")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/db")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/log")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/scripts")
      FileUtils.makedirs("#{ENV['HOME']}/.antfarm/tmp")
      `cp #{ANTFARM_ROOT}/templates/defaults_template_file.yml #{ENV['HOME']}/.antfarm/config/defaults.yml`
      `cp #{ANTFARM_ROOT}/templates/colors_template_file.xml #{ENV['HOME']}/.antfarm/config/colors.xml`
    end

    # Removes the database based on the ANTFARM environment given
    def db_remove
      `rm #{Antfarm.log_file_to_use}` if File.exists?(Antfarm.log_file_to_use)
      `rm #{Antfarm.db_file_to_use}` if File.exists?(Antfarm.db_file_to_use)
    end

    # Removes any database, schema, and log files found
    def db_clean
      Find.find(Antfarm.db_dir_to_use) do |path|
        if File.basename(path) == 'migrate'
          Find.prune
        else
          `rm #{path}` unless File.basename(path) == 'db' || File.basename(path) == 'schema.rb'
        end
      end

      Find.find(Antfarm.log_dir_to_use) do |path|
        `rm #{path}` unless File.basename(path) == 'log'
      end

      Find.find(Antfarm.tmp_dir_to_use) do |path|
        `rm #{path}` unless File.basename(path) == 'tmp'
      end
    end

    # Creates a new database and schema file.  The location of the newly created
    # database file is set in the initializer class via the ActiveRecord 
    # configuration hash, and is based on the current ANTFARM environment.
    def db_migrate
      if File.exists?(File.expand_path("#{ANTFARM_ROOT}/db/schema.rb"))
        load(File.expand_path("#{ANTFARM_ROOT}/db/schema.rb"))
      else
        puts "A schema file did not exist. Running migrations instead."

        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate(ANTFARM_ROOT + "/db/migrate/", nil)
        db_schema_dump if ActiveRecord::Base.schema_format == :ruby
      end
    end

    def db_reset
      db_remove
      db_migrate
    end

    def db_console
      puts "Loading #{ANTFARM_ENV} environment"
      exec "sqlite3 #{Antfarm.db_file_to_use}"
    end

    def db_schema_dump
      require 'active_record/schema_dumper'

      File.open(File.expand_path("#{ANTFARM_ROOT}/db/schema.rb"), "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end

end
