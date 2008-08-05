#!/usr/bin/ruby -w

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

require 'antfarm'

require 'antfarm/layer2/ethernet'
require 'antfarm/layer3/ip'

require 'antfarm/simplify'

# Pull in DB username/password and other configuration settings
require 'antfarm-config.rb'


@db = DBI.connect($dbname, $dblogin, $dbpasswd)
verbose = true

def nodes_to_graphviz
  node_str_array = Array.new
  query_str = "SELECT"
  query_str += " id, certainty_factor, type"
  query_str += " FROM Node"
  query_str += " ORDER BY certainty_factor"
  res = @db.prepare(query_str)
  res.execute

  while row = res.fetch
    node_str = "\"host.#{row[0]}\";"
    node_str_array.push(node_str)
  end

  res.finish
  return node_str_array
end


def relations_to_graphviz
  rel_str_array = Array.new
  query_str = "SELECT"
  query_str += " id, certainty_factor"
  query_str += " FROM Layer3_Network"
  query_str += " ORDER BY certainty_factor"
  res = @db.prepare(query_str)
  res.execute

  while row = res.fetch
    hyperedge_str = "\"switch.#{row[0].to_i}\" [label=\"\",shape=diamond];"
    rel_str_array.push(hyperedge_str)

    for relend_str in interfaces_to_graphviz(row[0].to_i)
      rel_str_array.push(relend_str)
    end
  end

  res.finish
  return rel_str_array
end


def interfaces_to_graphviz(layer3_net_id)
  interface_str_array = Array.new

  query_str = "SELECT DISTINCT"
  query_str += " L2_If.id, L2_If.certainty_factor,"
  query_str += " L2_If.node_id"
  query_str += " FROM Layer2_Interface AS L2_If"
  query_str += " JOIN Layer3_Interface AS L3_If"
  query_str += " ON L2_If.id = L3_If.layer2_interface_id"
  query_str += " WHERE L3_If.layer3_network_id = #{layer3_net_id}"
  query_str += " ORDER BY L2_If.certainty_factor"
  layer2_if_res = @db.prepare(query_str)
  layer2_if_res.execute

  while layer2_if_row = layer2_if_res.fetch
    layer2_if_id = layer2_if_row[0].to_i
    node_id = layer2_if_row[2].to_i

    edge_str = "\"switch.#{layer3_net_id}\" -- \"host.#{node_id}\""

    query_str = "SELECT DISTINCT"
    query_str += " IP_If.address"
    query_str += " FROM IP_Interface AS IP_If"
    query_str += " JOIN Layer3_Interface AS L3_If"
    query_str += " ON IP_If.id = L3_If.id"
    query_str += " WHERE"
    query_str += " L3_If.layer2_interface_id = #{layer2_if_id}"
    query_str += " ORDER BY IP_If.address"
    ip_if_res = @db.prepare(query_str)
    ip_if_res.execute

    label = "\""

    while ip_if_row = ip_if_res.fetch
      ip_address_str = ip_if_row[0]
      ip_address_str += "\\n"
      label += ip_address_str
    end

    label += "\""

    edge_str += " [headlabel = #{label}, labeldistance = 4.0, labelangle = 10.0, weight = 2.0];"

    interface_str_array.push(edge_str)
  end
  return interface_str_array
end


puts "graph antfarm {"
puts nodes_to_graphviz
puts relations_to_graphviz
puts "}"


# ./dump-graphviz.rb | circo -v -Tsvg -o test.svg
# ./dump-graphviz.rb | fdp -v -Tsvg -o test.svg
