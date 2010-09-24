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
# This script is modeled after the Rails boot script.

ANTFARM_ROOT = (ENV['ANTFARM_ROOT'] || File.expand_path(File.dirname(__FILE__) + '/..')).dup unless defined? ANTFARM_ROOT

module Antfarm
  class << self
    def boot!
      unless booted?
        require ANTFARM_ROOT + '/lib/antfarm/initializer'
        Antfarm::Initializer.run(:setup)
      end
    end

    def booted?
      defined? Antfarm::Initializer
    end
  end
end

Antfarm.boot!
