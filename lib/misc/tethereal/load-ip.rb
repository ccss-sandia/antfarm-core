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

ethernet_if_table = Antfarm::Ethernet_Interface.new(db, verbose)
ip_if_table = Antfarm::IP_Interface.new(db, verbose)

ip_src_dst_regexp = Regexp.new('([\d\.]+) -> ([\d\.]+)')

ip_addr_list = Array.new
list = File.open(ARGV[0])
list.each {|line|
  if m = ip_src_dst_regexp.match(line)
    ip_src_addr = m[1]
    ip_dst_addr = m[2]
    ip_addr_list.push(ip_src_addr)
    ip_addr_list.push(ip_dst_addr)
  end
}
list.close

ip_addr_list.uniq!.sort!
ip_addr_list.each {|ip_addr|
  #puts "'#{ip_addr}'"
  ip_if_table.insert(0.75, ip_addr)
}

db.disconnect

# tethereal -n -r CITGO_051205_1414_IT 'arp' > CITGO_051205_1414_IT-arp.txt
# tethereal -n -r CITGO_051205_1414_IT 'ip and ip.dst_host != 146.146.167.255 and not (ip.host >= 224.0.0.0 and ip.host <= 224.255.255.255)' > CITGO_051205_1414_IT-ip.txt
