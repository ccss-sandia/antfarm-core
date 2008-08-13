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
  puts "Usage: antfarm [options] viz [options] dump-graphml <output file>"
  puts
  puts "This script dumps the ANTFARM database to a GraphML format suitable"
  puts "for import into many graphing tools, such as Prefuse.  This is an"
  puts "all-inclusive script that dumps everything in the database.  For a"
  puts "less detailed graph, please use this script as an example for writing"
  puts "your own custom GraphML script."
  puts
end

def dump(file)
  output = File.open(file, "w")

  # TODO: how to fill this array from command line?
  cs_network_list = 
    [ '10.60.5.1',
      '10.60.5.2',
      '10.60.5.3',
      '10.60.5.4',
      '10.60.5.5',
      '10.60.5.6',
      '10.60.5.7',
      '10.60.5.8',
      '10.60.5.9',
      '10.60.5.10',
      '10.60.5.11',
      '10.60.5.12',
      '204.136.3.68',
      '204.136.3.69',
      '192.168.18.10',
      '192.168.18.11',
      '192.168.4.1',
      '192.168.4.2',
      '192.168.4.3',
      '192.168.4.4',
      '192.168.4.5',
      '192.168.4.6',
      '192.168.4.7',
      '10.177.21.100' ]

  cs_network_list = nil

  output.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  output.puts "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">"
  output.puts "  <graph edgedefault=\"undirected\">"
  output.puts "    <key id=\"name\" for=\"node\" attr.name=\"name\" attr.type=\"string\" />"
  output.puts "    <key id=\"type\" for=\"node\" attr.name=\"type\" attr.type=\"string\" />"
  output.puts "    <key id=\"line\" for=\"edge\" attr.name=\"line\" attr.type=\"string\" />"

#  output.puts "    <node id=\"inet_super_router\">"
#  output.puts "      <data key=\"name\">Internet Super Router</data>"
#  output.puts "      <data key=\"type\">ISR</data>"
#  output.puts "    </node>"
#
#  output.puts "    <node id=\"corp_super_router\">"
#  output.puts "      <data key=\"name\">Corporate Super Router</data>"
#  output.puts "      <data key=\"type\">CSR</data>"
#  output.puts "    </node>"

  networks = Array.new

# Node.find_all_by_type("Layer 3 Device").each do |node|
  Node.find(:all).each do |node|
    created_node = false
    node.layer3_interfaces.each do |l3_if|
      network = Antfarm::IPAddrExt.new(l3_if.layer3_network.ip_network.address.to_s)
      if cs_network_list.nil? || cs_network_list.empty? || network.in_address_list?(cs_network_list)
        unless created_node
          output.puts "    <node id=\"node_#{node.id}\">"
#         output.puts "      <data key=\"name\">#{node.name.nil? ? "Layer 3 Device" : node.name}</data>"
          output.puts "      <data key=\"name\">#{node.name.nil? ? node.device_type : node.name}</data>"
#         output.puts "      <data key=\"type\">#{node.device_type}</data>" unless node.device_type.nil?
          output.puts "      <data key=\"type\">#{node.device_type}</data>"
          output.puts "    </node>"
          created_node = true
        end

#       output.puts "    <node id=\"if_#{l3_if.id}\">"
#       output.puts "      <data key=\"name\">#{l3_if.ip_interface.address.to_s}</data>"
#       output.puts "      <data key=\"type\">INTERFACE</data>"
#       output.puts "    </node>"

        unless networks.include?(l3_if.layer3_network.id)
          output.puts "    <node id=\"network_#{l3_if.layer3_network.id}\">"
          output.puts "      <data key=\"name\">#{l3_if.layer3_network.ip_network.address.to_s}</data>"
          output.puts "      <data key=\"type\">#{l3_if.layer3_network.ip_network.private ? "PRIVATE" : "PUBLIC"}</data>"
          output.puts "    </node>"
          networks << l3_if.layer3_network.id
        end

#       output.puts "    <edge source=\"node_#{node.id}\" target=\"if_#{l3_if.id}\" />"
#       output.puts "    <edge source=\"if_#{l3_if.id}\" target=\"network_#{l3_if.layer3_network.id}\" />"
        output.puts "    <edge source=\"node_#{node.id}\" target=\"network_#{l3_if.layer3_network.id}\" />"
      end
    end
  end

#  node_list = Array.new
#
#  ip_net_res = @db_handle.prepare("SELECT id, address, private_network FROM IP_Network")
#  ip_net_res.execute
#
#  connection_res = @db_handle.prepare("SELECT id, description, from_node_id, to_node_id FROM Connection")
#  connection_res.execute
#
#  unless @options.cs_addr_list_file.nil?
#    cs_addr_list = Array.new
#    list = File.open(@options.cs_addr_list_file)
#
#    list.each do |line|
#      line.strip!
#      cs_addr_list << line if !line.empty?
#    end
#
#    list.close
#  end
#
#  while ip_net_row = ip_net_res.fetch
#    ip_net_id = ip_net_row[0]
#    ip_net_addr = ip_net_row[1]
#    ip_net_private = ip_net_row[2]
#
#    network = IPAddrExt.new(ip_net_addr)
#
#    if ip_net_private
#      if cs_addr_list.nil? || cs_addr_list.empty? || network.in_address_list?(cs_addr_list)
#        output.puts "    <node id=\"network_#{ip_net_id}\">"
#        output.puts "      <data key=\"name\">#{ip_net_addr}</data>"
#        output.puts "      <data key=\"type\">PRI</data>"
#        output.puts "    </node>"
#
#        node_list = graph_table.ip_if_having_ip_net(ip_net_id, node_list, output)
#      else
#        node_list = graph_table.ip_if_having_ip_net(ip_net_id, node_list, output, "corp_super_router")
#      end
#    else
#      if cs_addr_list.nil? || cs_addr_list.empty? || network.in_address_list?(cs_addr_list)
#        output.puts "    <node id=\"network_#{ip_net_id}\">"
#        output.puts "      <data key=\"name\">#{ip_net_addr}</data>"
#        output.puts "      <data key=\"type\">PUB</data>"
#        output.puts "    </node>"
#
#        node_list = graph_table.ip_if_having_ip_net(ip_net_id, node_list, output)
#      else
#        node_list = graph_table.ip_if_having_ip_net(ip_net_id, node_list, output, "inet_super_router")
#      end
#    end
#  end
#
#  while connection_row = connection_res.fetch
#    description = connection_row[1]
#    from_node_id = connection_row[2]
#    to_node_id = connection_row[3]
#
#    output.puts "    <edge source=\"node_#{from_node_id}\" target=\"node_#{to_node_id}\">"
#    output.puts "      <data key=\"line\">#{description}</data>"
#    output.puts "    </edge>"
#  end

  node_list = Array.new
  Traffic.find(:all).each do |traffic|
    source_node = traffic.source_layer3_interface.layer2_interface.node
    target_node = traffic.target_layer3_interface.layer2_interface.node

    unless node_list.include?(source_node)
      output.puts "    <node id=\"node_#{source_node.id}\">"
      output.puts "      <data key=\"name\">#{source_node.name.nil? ? source_node.device_type : source_node.name}</data>"
      output.puts "      <data key=\"type\">#{source_node.device_type}</data>"
      output.puts "    </node>"
    end

    unless node_list.include?(target_node)
      output.puts "    <node id=\"node_#{target_node.id}\">"
      output.puts "      <data key=\"name\">#{target_node.name.nil? ? target_node.device_type : target_node.name}</data>"
      output.puts "      <data key=\"type\">#{target_node.device_type}</data>"
      output.puts "    </node>"
    end

    output.puts "    <edge source=\"node_#{source_node.id}\" target=\"node_#{target_node.id}\">"
    output.puts "      <data key=\"line\">PCAP</data>"
    output.puts "    </edge>"
  end

  output.puts "  </graph>"
  output.puts "</graphml>"

  output.close
end

if ARGV.empty? || ARGV.length > 1 || ARGV[0] == '--help'
  print_help
else
  dump(ARGV[0])
end
