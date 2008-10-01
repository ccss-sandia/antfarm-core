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
  puts "Usage: antfarm [options] viz [options] display-traffic"
  puts
  puts "This script utilizes the provided Prefuse-based Java application"
  puts "to display traffic contained in the current database."
  puts
  puts "Script Options:"
  puts "  --collapse-ports    Only include one node for each port number"
  puts "                      discovered."
end

def display(options = [])
  output = File.open("#{Antfarm.tmp_dir_to_use}/traffic.gml", "w")
  output.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  output.puts "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\">"
  output.puts "  <graph edgedefault=\"undirected\">"
  output.puts "    <key id=\"name\" for=\"node\" attr.name=\"name\" attr.type=\"string\" />"
  output.puts "    <key id=\"type\" for=\"node\" attr.name=\"type\" attr.type=\"string\" />"
  output.puts "    <key id=\"line\" for=\"edge\" attr.name=\"line\" attr.type=\"string\" />"
  nodes = Array.new
  ports = Array.new
  Traffic.find(:all).each do |traffic|
    source_node = traffic.source_layer3_interface.layer2_interface.node
    target_node = traffic.target_layer3_interface.layer2_interface.node
    port = traffic.port
    unless nodes.include?(source_node)
      output.puts "    <node id=\"node_#{source_node.id}\">"
      output.puts "      <data key=\"name\">#{source_node.name.nil? ? source_node.device_type : source_node.name}</data>"
      output.puts "      <data key=\"type\">#{source_node.device_type}</data>"
      output.puts "    </node>"
      nodes << source_node
    end
    unless nodes.include?(target_node)
      output.puts "    <node id=\"node_#{target_node.id}\">"
      output.puts "      <data key=\"name\">#{target_node.name.nil? ? target_node.device_type : target_node.name}</data>"
      output.puts "      <data key=\"type\">#{target_node.device_type}</data>"
      output.puts "    </node>"
      nodes << target_node
    end
    if port.zero?
      output.puts "    <edge source=\"node_#{source_node.id}\" target=\"node_#{target_node.id}\">"
      output.puts "      <data key=\"line\">#{traffic.description}-PORTLESS</data>"
      output.puts "    </edge>"
    else
      if options.include?('--collapse-ports')
        unless ports.include?(port)
          output.puts "    <node id=\"port_#{port}\">"
          output.puts "      <data key=\"name\">#{port}</data>"
          output.puts "      <data key=\"type\">PORT</data>"
          output.puts "    </node>"
          ports << port
        end
        output.puts "    <edge source=\"node_#{source_node.id}\" target=\"port_#{port}\">"
        output.puts "      <data key=\"line\">#{traffic.description}</data>"
        output.puts "    </edge>"
        output.puts "    <edge source=\"port_#{port}\" target=\"node_#{target_node.id}\">"
        output.puts "      <data key=\"line\">#{traffic.description}</data>"
        output.puts "    </edge>"
      else
        output.puts "    <node id=\"port_#{source_node.id}_#{target_node.id}_#{port}\">"
        output.puts "      <data key=\"name\">#{port}</data>"
        output.puts "      <data key=\"type\">PORT</data>"
        output.puts "    </node>"
        output.puts "    <edge source=\"node_#{source_node.id}\" target=\"port_#{source_node.id}_#{target_node.id}_#{port}\">"
        output.puts "      <data key=\"line\">#{traffic.description}</data>"
        output.puts "    </edge>"
        output.puts "    <edge source=\"port_#{source_node.id}_#{target_node.id}_#{port}\" target=\"node_#{target_node.id}\">"
        output.puts "      <data key=\"line\">#{traffic.description}</data>"
        output.puts "    </edge>"
      end
    end
  end
  output.puts "  </graph>"
  output.puts "</graphml>"
  output.close

  if (defined? USER_DIR) && File.exists?("#{USER_DIR}/config/colors.xml")
    `java -jar #{ANTFARM_ROOT}/lib/antfarm.jar -tree -colors #{USER_DIR}/config/colors.xml #{Antfarm.tmp_dir_to_use}/traffic.gml`
  else
    `java -jar #{ANTFARM_ROOT}/lib/antfarm.jar -tree #{Antfarm.tmp_dir_to_use}/traffic.gml`
  end
end

if ['-h', '--help'].include?(ARGV[0])
  print_help
else
  display(ARGV)
end
