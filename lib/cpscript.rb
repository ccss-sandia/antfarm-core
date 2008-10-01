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
  class CPScript < SCParse::Command
    def initialize
      # set the command name to 'cp'
      super('cp-script')
    end

    def execute(args)
      super(args)

      if defined?(USER_DIR)
        script = args.pop + '.rb'
        parents = args.join('/')
        location = File.expand_path("#{ANTFARM_ROOT}/lib/scripts/#{parents}/#{script}")
        if File.exists?(location)
          FileUtils.makedirs("#{USER_DIR}/scripts/#{parents}")
          FileUtils.cp(location, "#{USER_DIR}/scripts/#{parents}/")
          if parents.empty?
            puts "The script #{script} has been copied to #{USER_DIR}/scripts/"
          else
            puts "The script #{script} has been copied to #{USER_DIR}/scripts/#{parents}/"
          end
        else
          if parents.empty?
            puts "The script #{script} doesn't seem to exist.  Please try again."
          else
            puts "The script #{parents}/#{script} doesn't seem to exist.  Please try again."
          end
        end
      else
        puts "No custom user directory exists.  Please run 'antfarm db --initialize' first."
      end
    end

    def show_help
      super

      puts "This command is used to copy scripts available in the core ANTFARM package to"
      puts "your user directory.  This is useful for utilizing existing core ANTFARM scripts"
      puts "as a basis for creating your own custom scripts."
      puts
      puts "As arguments to this command, specify the script you want to copy to your user"
      puts "directory.  For example: antfarm cp-script cisco parse-arp"
    end
  end
end
