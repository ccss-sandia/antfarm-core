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
  puts "Usage: antfarm [options] load-network <network file>"
  puts
  puts "The network file should contain a list of IP"
  puts "network addresses, one per line."
end

# Parses the given file, creating an IP Interface for
# each IP address.
def parse(file)
  begin
    list = File.open(file)
  rescue Errno::ENOENT
    puts "The file '#{file}' does not exist"
    exit
  end

  list.each do |line|
    IpNetwork.create :address => line.strip
  end
end

if ARGV.empty? || ARGV.length > 1 || ARGV[0] == '--help'
  print_help
else
  parse(ARGV[0])
end

