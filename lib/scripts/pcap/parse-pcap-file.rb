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
  puts "Usage: antfarm [options] pcap [options] parse-pcap-file <pcap file>"
  puts
  puts "This script parses a libPcap file containing traffic capture data,"
  puts "creating an IP interface for each endpoint and a traffic object"
  puts "for the traffic between them.  Node device types are set to 'PCAP',"
  puts "as well as traffic descriptions."
end

def parse(file)
  cap = Pcap::Capture.open_offline(ARGV[0])
  cap.each do |pkt|
    if pkt.ip?
      source_ip_addr = pkt.src.to_num_s
      target_ip_addr = pkt.dst.to_num_s

      source_l3_net = Layer3Network.network_containing(source_ip_addr)
      target_l3_net = Layer3Network.network_containing(target_ip_addr)

      if source_l3_net && target_l3_net
        puts "Added traffic -- #{source_ip_addr} ==> #{target_ip_addr}"

        source_ip_iface = IpInterface.create :address => source_ip_addr, :layer3_network => source_l3_net, :node_device_type => "PCAP"
        target_ip_iface = IpInterface.create :address => target_ip_addr, :layer3_network => target_l3_net, :node_device_type => "PCAP"

        Traffic.create :source_layer3_interface => source_ip_iface.layer3_interface, \
                       :target_layer3_interface => target_ip_iface.layer3_interface, \
                       :description => "PCAP"
      end
    end
  end
end

if ARGV.empty? || ARGV.length > 1 || ARGV[0] == '--help'
  print_help
else
  parse(ARGV[0])
end

