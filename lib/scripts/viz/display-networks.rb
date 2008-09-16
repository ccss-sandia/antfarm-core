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
  puts "Usage: antfarm [options] viz [options] display-networks"
  puts
  puts "This script utilizes the provided Prefuse-based Java application"
  puts "to display the networks contained in the current database."
  puts
end

def display
  output = File.open("#{Antfarm.tmp_dir_to_use}/network.gml", "w")
  output.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  output.puts "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">"
  output.puts "  <graph edgedefault=\"undirected\">"
  output.puts "    <key id=\"name\" for=\"node\" attr.name=\"name\" attr.type=\"string\" />"
  output.puts "    <key id=\"type\" for=\"node\" attr.name=\"type\" attr.type=\"string\" />"
  output.puts "    <key id=\"line\" for=\"edge\" attr.name=\"line\" attr.type=\"string\" />"
  networks = Array.new
  Node.find(:all).each do |node|
    created_node = false
    node.layer3_interfaces.each do |l3_if|
      network = Antfarm::IPAddrExt.new(l3_if.layer3_network.ip_network.address.to_s)
      unless created_node
        output.puts "    <node id=\"node_#{node.id}\">"
        output.puts "      <data key=\"name\">#{node.name.nil? ? node.device_type : node.name}</data>"
        output.puts "      <data key=\"type\">#{node.device_type}</data>"
        output.puts "    </node>"
        created_node = true
      end
      unless networks.include?(l3_if.layer3_network.id)
        output.puts "    <node id=\"network_#{l3_if.layer3_network.id}\">"
        output.puts "      <data key=\"name\">#{l3_if.layer3_network.ip_network.address.to_s}</data>"
        output.puts "      <data key=\"type\">#{l3_if.layer3_network.ip_network.private ? "PRIVATE" : "PUBLIC"}</data>"
        output.puts "    </node>"
        networks << l3_if.layer3_network.id
      end
      output.puts "    <edge source=\"node_#{node.id}\" target=\"network_#{l3_if.layer3_network.id}\" />"
    end
  end
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
    output.puts "      <data key=\"line\">#{traffic.description}</data>"
    output.puts "    </edge>"
  end
  output.puts "  </graph>"
  output.puts "</graphml>"
  output.close

  if (defined? USER_DIR) && File.exists?("#{USER_DIR}/config/colors.xml")
    `java -jar #{ANTFARM_ROOT}/lib/antfarm.jar -active -colors #{USER_DIR}/config/colors.xml #{Antfarm.tmp_dir_to_use}/network.gml`
  else
    `java -jar #{ANTFARM_ROOT}/lib/antfarm.jar -active #{Antfarm.tmp_dir_to_use}/network.gml`
  end
end

if ARGV.length > 0
  print_help
else
  display
end
