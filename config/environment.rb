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
# This script is modeled after the Rails environment configuration script.

ANTFARM_ENV       = (ENV['ANTFARM_ENV'] || 'antfarm').dup unless defined? ANTFARM_ENV
ANTFARM_LOG_LEVEL = (ENV['ANTFARM_LOG_LEVEL'] || 'warn').dup unless defined? ANTFARM_LOG_LEVEL

require File.dirname(__FILE__) + '/boot'

Antfarm::Initializer.run do |config|
  config.log_level = ANTFARM_LOG_LEVEL
end
