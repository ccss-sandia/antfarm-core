#!/usr/bin/ruby

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
  puts "Usage: antfarm [options] cisco [options] parse-arp [directories ...] [files ...]"
  puts
  puts "This script parses an ARP dump from a Cisco network device and creates the"
  puts "appropriate IP and ethernet interfaces.  This script assumes the ARP dump"
  puts "file(s) are in the following format:"
  puts
  puts "<other junk> ip_address ethernet_address"
  puts
end

def parse(file)
  list = File.open(file)

  list.each do |line|
    (junk, ip_addr, ethernet_addr) = line.split(' ')
    ip_addr.strip!
    ethernet_addr.strip!

    IpInterface.create(:address => ip_addr, :ethernet_address => ethernet_addr)
  end

  list.close

  # TODO: merge by ethernet address
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

