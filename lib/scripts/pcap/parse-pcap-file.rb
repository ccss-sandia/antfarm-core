#! /usr/bin/ruby

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

require 'pcap'

def print_help
  puts "Usage: antfarm [options] pcap [options] parse-pcap-file [options] <pcap file>"
  puts
  puts "This script parses a libPcap file containing traffic capture data,"
  puts "creating an IP interface for each endpoint and a traffic object"
  puts "for the traffic between them.  Node device types are set to 'PCAP',"
  puts "as well as traffic descriptions."
  puts 
  puts "Script Options:"
  puts "  --create-new-networks    Create new networks if networks containing the"
  puts "                           source or destination address don't already exist."
end

def parse(file, options = [])
  cap = Pcap::Capture.open_offline(ARGV[0])
  cap.each do |pkt|
    if pkt.ip?
      source_addr = pkt.src.to_num_s
      target_addr = pkt.dst.to_num_s
      if options.include?('--create-new-networks')
        source_iface = IpInterface.find_or_create_by_address(source_addr)
        target_iface = IpInterface.find_or_create_by_address(target_addr)
        traffic = Traffic.new :source_layer3_interface => source_iface.layer3_interface, \
                              :target_layer3_interface => target_iface.layer3_interface, \
                              :description => "PCAP"
        traffic.port = pkt.dport if pkt.tcp? || pkt.udp?
        traffic.save false
        puts "Added traffic -- #{source_addr} ==> #{target_addr}"
      else
        source_net = Layer3Network.network_containing(source_addr)
        target_net = Layer3Network.network_containing(target_addr)
        if source_net && target_net
          source_iface = IpInterface.find_or_create_by_address(source_addr)
          target_iface = IpInterface.find_or_create_by_address(target_addr)
          traffic = Traffic.new :source_layer3_interface => source_iface.layer3_interface, \
                                :target_layer3_interface => target_iface.layer3_interface, \
                                :description => "PCAP"
          traffic.port = pkt.dport if pkt.tcp? || pkt.udp?
          traffic.save false
          puts "Added traffic -- #{source_addr} ==> #{target_addr}"
        end
      end
    end
  end
end

if ['-h', '--help'].include?(ARGV[0])
  print_help
else
  parse(ARGV.pop, ARGV)
end
