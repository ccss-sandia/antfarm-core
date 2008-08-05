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
  puts "Usage: antfarm [options] cisco [options] parse-routes [directories ...] [files ...]"
  puts
  puts "This script parses routes from Cisco layer 3 network devices and creates Traffic"
  puts "data for them.  For each configuration file parsed, the script uses the host name"
  puts "to get the source node of the route and uses the IP address from the route to get"
  puts "the target for the route.  The source and target must already exist for the route"
  puts "to be created (run parse-ip-ifaces before running this script)."
  puts
end

def parse(file)
  puts file

  hostname_regexp = Regexp.new('^hostname (\S+)')
  ipv4_regexp =     Regexp.new('((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
  route_regexp =    Regexp.new('^route (\S+) %s %s %s' % [ipv4_regexp, ipv4_regexp, ipv4_regexp])

  hostname = nil
  ip_addrs = Array.new

  list = File.open(file)

  list.each do |line|
    # Get hostname
    if name = hostname_regexp.match(line)
      hostname = name[1]
    end

    # Get routes
    if route = route_regexp.match(line)
      ip_addrs << route[12]
    end
  end

  node = Node.find_by_name(hostname)
  unless node.nil? || node.layer3_interfaces.nil?
    source_l3_iface = node.layer3_interfaces[0]

    ip_addrs.each do |ip_addr|
      target_l3_iface = Layer3Interface.interface_addressed(ip_addr)
      Traffic.create(:source_layer3_interface => source_l3_iface, :target_layer3_interface => target_l3_iface, :type => "Route") unless target_l3_iface.nil?
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
