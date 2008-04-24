
# Copyright 2004  Sandia National Laboratories
# Original Author: Michael Berg <mjberg@sandia.gov>

require 'antfarm/common'
require 'antfarm/node'
require 'antfarm/layer3/ip'

module Antfarm

  class IP_Path < AntfarmObject

    def initialize(db_handle, verbose = false)
      super(db_handle, verbose)

      @node_table = Node.new(db, verbose)
      @layer2_if_table = Layer2_Interface.new(db, verbose)
      @layer3_if_table = Layer3_Interface.new(db, verbose)
      @ip_net_table = IP_Network.new(db, verbose)
      @ip_if_table = IP_Interface.new(db, verbose)
    end


    def insert(addr_path)
      path = Array.new
      node_id_path = Array.new

      # Insert the nodes
      for addr in addr_path
        if addr
          iface = Hash.new
          # Insert IP address
          ip_if_id = @ip_if_table.insert(0.75, addr)
          # Get IP network and Node associated with the IP
          ip_net_id = @ip_if_table.layer3_network_having(ip_if_id)
          layer2_if_id = @ip_if_table.layer2_interface_having(ip_if_id)
          node_id = @layer2_if_table.node_having(layer2_if_id)
          # Store the needed information for the next step
          iface['ip_interface_id'] = ip_if_id
          iface['ip_network_id'] = ip_net_id
          iface['node_id'] = node_id
          path.push(iface)
          node_id_path.push(node_id)
        end
      end

      # Insert the edges
      for i in 0..(path.size - 2)
        u = path[i]
        v = path[i + 1]
        if u and v
          # Get nodes connected to the IP network
          connected_nodes = @ip_net_table.nodes_connected_to(v['ip_network_id'])
          unless connected_nodes.include?(u['node_id'])
            # Create a new Layer2_Interface for the Node
            layer2_if_id = @layer2_if_table.insert(CF_LACK_OF_PROOF, nil,
                                                   u['node_id'])
            # Connect a new "unknown" Layer3_Interface that
            # is connected to the specified layer3_net_id
            @layer3_if_table.insert(CF_LACK_OF_PROOF, "IP",
                                    v['ip_network_id'], layer2_if_id)

          end
        end
      end

      return node_id_path
    end

  end  # class NetworkPath

end  # module Antfarm
