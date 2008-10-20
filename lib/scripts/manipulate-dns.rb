#!/usr/bin/ruby

# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
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
  puts "Usage: antfarm [options] manipulate-dns [options]"
  puts
  puts "Script Options:"
  puts "  --merge-entries    Find duplicate entries in the table and merge them"
  puts "  --name-nodes       Set node names using DNS entries"
  puts "  --merge-nodes      Find entries with the same hostname but different IP"
  puts "                     addresses and merge the nodes for those interfaces"
end

def merge_entries
  entries = DnsEntry.find(:all)
  while !entries.empty?
    entry = entries.shift
    entries.each do |e|
      e.destroy if entry.address == e.address && entry.hostname == e.hostname
      entries.delete(e)
    end
  end
end

def name_nodes
  entries = DnsEntry.find(:all)
  entries.each do |entry|
    iface = IpInterface.find :first, :conditions => { :address => entry.address }
    if iface
      node = iface.layer3_interface.layer2_interface.node
      node.name = entry.hostname unless node.nil?
      node.save false
    end
  end
end

def merge_nodes
  entries = DnsEntry.find(:all)
  while !entries.empty?
    entry = entries.shift
    entries.each do |e|
      if entry.hostname == e.hostname
        iface0 = IpInterface.find :first, :conditions => { :address => entry.address }
        iface1 = IpInterface.find :first, :conditions => { :address => e.address }
        l2_iface = iface1.layer3_interface.layer2_interface
        l2_iface.node.destroy
        l2_iface.node = iface0.layer3_interface.layer2_interface.node
        l2_iface.save false
        entries.delete(e)
      end
    end
  end
end

if ['-h', '--help'].include?(ARGV[0])
  print_help
else
  if ARGV.include?('--merge-entries')
    merge_entries
  end
  if ARGV.include?('--name-nodes')
    name_nodes
  end
  if ARGV.include?('--merge-nodes')
    merge_nodes
  end
end
