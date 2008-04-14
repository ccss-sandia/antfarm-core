#!/usr/bin/ruby

def insert(addr_path)
  path = Array.new
  node_path = Array.new

  # Insert the nodes
  for addr in addr_path
    if addr
      iface = Hash.new
      # Insert IP address
      ip_if = IpInterface.create(:address => addr)
      # Store the needed information for the next step
      iface['ip_interface'] = ip_if
      iface['ip_network'] = ip_if.layer3_interface.layer3_network.ip_network
      iface['node'] = ip_if.layer3_interface.layer2_interface.node
      path.push(iface)
      node_path.push(ip_if.layer3_interface.layer2_interface.node)
    end
  end

  # Insert the edges
  for i in 0..(path.size - 2)
    u = path[i]
    v = path[i + 1]
    if u and v
      # Get nodes connected to the IP network
      connected_nodes = Array.new
      v['ip_network'].layer3_network.layer3_interfaces.each do |l3_if|
        connected_nodes << l3_if.layer2_interface.node
      end
      unless connected_nodes.include?(u['node'])
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

def parse
  path = ['146.146.161.250', '146.146.150.6']
  insert(path)

  path = ['146.146.161.250', '146.146.151.224']
  insert(path)

  path = ['146.146.161.253', '146.146.252.185', '146.146.111.253',
          '146.146.249.202', '209.64.200.65', '146.146.4.11']
  insert(path)
end
