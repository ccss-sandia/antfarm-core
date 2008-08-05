#!/usr/bin/env ruby

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

def print_help
  puts "Usage: antfarm [options] cisco [options] parse-network-objects [directories ...] [files ...]"
  puts
  puts "This script parses a Cisco IOS configuration file, creating a new IP Interface for each"
  puts "network object host specified."
end

def parse(file)
  puts file

  net_obj_host_regexp = Regexp.new('^\s*network-object host ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')

  net_obj_hosts = Array.new

  list = File.open(file)

  list.each do |line|
    # Get network object hosts
    if net_obj_host = net_obj_host_regexp.match(line)
      net_obj_hosts << net_obj_host[1]
    end
  end

  list.close

  net_obj_hosts.uniq!
  net_obj_hosts.each do |address|
    if Layer3Network.network_containing(address)
      ip_iface = IpInterface.new :address => address
      ip_iface.node_name = address
      ip_iface.node_device_type = "HOST"
      
      unless ip_iface.save
        ip_iface.errors.each_full do |msg|
          puts msg
        end
      end
    end
  end
end

if ARGV[0] == '--help'
  print_help
else
  ARGV.each do |arg|
    if File.directory?(arg)
      Find.find(arg) do |path|
        if File.file?(path)
          parse(path)
        end
      end
    else
      parse(arg)
    end
  end
end

