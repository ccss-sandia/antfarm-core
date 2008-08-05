#!/usr/bin/ruby -w

# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Michael Berg, Sandia National Laboratories <mjberg@sandia.gov>
# Modified By: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
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

require 'antfarm'

require 'antfarm/layer2/ethernet'
require 'antfarm/layer3/ip'

require 'antfarm/simplify'

# Pull in DB username/password and other configuration settings
require 'antfarm-config.rb'


db = DBI.connect($dbname, $dblogin, $dbpasswd)
verbose = true

node_table = Antfarm::Node.new(db)
layer2_if_table = Antfarm::Layer2_Interface.new(db, verbose)
ip_if_table = Antfarm::IP_Interface.new(db, verbose)

list = File.open(ARGV[0])

router_name = list.readline.strip!
new_node_id = node_table.insert(0.75, router_name)

list.each {|line|
  ip_addr = line
  ip_addr.strip!

  ip_if_id = ip_if_table.insert(0.75, ip_addr)
  # Get Node associated with the IP
  layer2_if_id = ip_if_table.layer2_interface_having(ip_if_id)
  node_id = layer2_if_table.node_having(layer2_if_id)
  # Merge the default anonymous node_id with the new router node_id
  node_table.merge(new_node_id, node_id)
}
list.close

db.disconnect
