#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'graph/spring'

def print_help
  puts "Usage: antfarm [options] render-graph"
end

def render
  graph = Antfarm::Graph::Graph.new

  node_map = Hash.new

  networks = Array.new

  # find all nodes in the system (routers, firewalls, hosts, etc)
  Node.find(:all).each do |node|
    created_node = false

    # do 'something' with each node's layer 3 interface
    node.layer3_interfaces.each do |l3_if|
      l3_network = l3_if.layer3_network

      # get the network this layer 3 interface is connected to
      network = Antfarm::IPAddrExt.new(l3_if.layer3_network.ip_network.address.to_s)

      # create this node unless it's already been created
      # (a node could have more than one layer 3 interface...)
      unless created_node
        puts node.device_type
        node_map[node] = Antfarm::Graph::SpringObject.new('green')
        graph.add :node => node_map[node]
        created_node = true
      end

      # create this layer 3 network unless it's already been created
      unless networks.include?(l3_if.layer3_network.id)
        node_map[l3_network] = Antfarm::Graph::SpringObject.new('red')
        graph.add :node => node_map[l3_network]
        networks << l3_if.layer3_network.id
      end

      graph.add :edge => Object.new, :endpoints => [node_map[node], node_map[l3_network]]
    end
  end

  root = TkRoot.new { title "A|N|T|F|A|R|M" }
  Antfarm::Graph::SpringLayout.new graph, [1000,800]
  Tk.mainloop
end

if ARGV[0] == '--help'
  print_help
else
  render
end

