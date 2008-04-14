#!/usr/bin/ruby -w

require 'ipinterface'
require 'antfarmdb'
require 'antfarmdb/gxl'
require 'antfarmdb/graphviz'

# Pull in DB username/password and other configuration settings
require 'antfarm_config.rb'


def parse_line_to_addr(line)
  pat_ipv4 = Regexp::new('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') # x.x.x.x
  if m = pat_ipv4.match(line)
    return m[0]
  end
  return nil
end


# Take data (anything where each line represents one hop farther
# into the network and where each line contains an IP address)
# and return an array of IP addresses representing the path taken.
def parse_data_to_addr_list(data)
  addr_list = Array.new
  for line in data
    if addr = parse_line_to_addr(line)
      addr_list.push(addr)
    else  # host didn't respond, record an unknown hop
      addr_list.push(nil)
    end
  end
  return addr_list
end


# returns an array of the node_ids along the path
def insert_traceroute_path(netdb, address_path)
  path = Array.new
  node_id_path = Array.new
  # Add the vertices
  for addr in address_path
    if addr
      iface = Hash.new
      ip = IPInterface.new(addr)
      ip_id = netdb.insert_ip_interface($cf_likely_true, ip)
      ip_network_id = netdb.layer3_network_having_layer3_interface(ip_id)
      node_id = netdb.node_having_layer3_interface(ip_id)
      iface['ip_id'] = ip_id
      iface['ip_network_id'] = ip_network_id
      iface['node_id'] = node_id
      path.push(iface)
      node_id_path.push(node_id)
    end
  end
  # Add the edges
  for i in 0..(path.size - 2)
    u = path[i]
    v = path[i + 1]
    if u and v
      netdb.connect_node_to_layer3_network(u['node_id'], v['ip_network_id'])
    end
  end

  return node_id_path
end


# returns an array of the node_ids along the path
def insert_routerecord_path(netdb, address_path)
  path = Array.new
  node_id_path = Array.new
  # Add the vertices
  for addr in address_path
    if addr
      iface = Hash.new
      ip = IPInterface.new(addr)
      ip_id = netdb.insert_ip_interface($cf_likely_true, ip)
      iface['ip_id'] = ip_id
      ip_network_id = netdb.layer3_network_having_layer3_interface(ip_id)
      iface['ip_network_id'] = ip_network_id
      node_id = netdb.node_having_layer3_interface(ip_id)
      iface['node_id'] = node_id
      path.push(iface)
      node_id_path.push(node_id)
    end
  end
  # Add the edges
  for i in 0..(path.size - 2)
    u = path[i]
    v = path[i + 1]
    if u and v
      netdb.connect_node_to_layer3_network(v['node_id'], u['ip_network_id'])
    end
  end

  return node_id_path
end


# returns an array of the node_ids inserted (order not significant)
def insert_addresses(netdb, address_list)
  node_id_list = Array.new
  for addr in address_list
    if addr
      ip = IPInterface.new(addr)
      ip_id = netdb.insert_ip_interface($cf_likely_true, ip)
      node_id = netdb.node_having_layer3_interface(ip_id)
      node_id_list.push(node_id)
    end
  end

  return node_id_list
end


# TODO: Find a better way that doesn't force the insertion
# of a new layer2_if_id every time.
def insert_arp(netdb, ip_addr_str, mac_addr_str)
  ip = IPInterface.new(ip_addr_str)
  layer3_if_id = netdb.insert_ip_interface($cf_likely_true, ip)
  layer2_if_id_old = netdb.layer2_interface_having_layer3_interface(layer3_if_id)
  node_id = netdb.node_having_layer2_interface(layer2_if_id_old)

  layer2_if_id_new = netdb.insert_ethernet_interface($cf_likely_true,
						     mac_addr_str,
						     node_id);
  netdb.merge_layer2_interfaces(layer2_if_id_new, layer2_if_id_old)
end


# Correlate TraceRoute (TR) and RouteRecord (RR) paths
def correlate_tr_rr(netdb, tr_path_data, rr_path_data)
  # Make copies I can work on destructively
  tr_path = tr_path_data.clone
  rr_path = rr_path_data.clone
  # TR path starts at the next hop.
  # RR path starts at the originating host.
  # Need to adjust for this, so remove first RR entry.
  rr_path.delete_at(0)
  # Correlate the rest of the entries
  for i in 0..([tr_path.length, rr_path.length].min - 1)
    tr_node_id = tr_path[i]
    rr_node_id = rr_path[i]
    # TODO: Put in some extra sanity checks here
    # like do both nodes have interfaces connected to the same two networks
    if (tr_node_id and rr_node_id) and (tr_node_id != rr_node_id)
      netdb.merge_nodes(tr_node_id, rr_node_id, 0.66)
    end
  end
end



# Start of actual prototype application

netdb = Antfarm::AntfarmDB.new('DBI:PG:ANTFARM', $dblogin, $dbpasswd)

#netdb.netmask_host_bits = 8

# Start a transaction.  This helps guarantee data integrity by not leaving
# a partially inserted results if this program runs into problems.
# It also has the added benefit of improving performance since the DB
# isn't doing an autocommit after each statement.
netdb.transaction_begin


traceroute_data_dir = 'data/traceroute'
file_list = Dir::glob("#{traceroute_data_dir}/*")
for file in file_list
  data = File.new(file)
  path = parse_data_to_addr_list(data)
  tr_path = insert_traceroute_path(netdb, path)
  data.close
end

routerecord_data_dir = 'data/routerecord'
file_list = Dir::glob("#{routerecord_data_dir}/*")
for file in file_list
  data = File.new(file)
  path = parse_data_to_addr_list(data)
  rr_path = insert_routerecord_path(netdb, path)
  data.close
end

# Correlate between traceroute and routerecord files
rr_file_list = Dir::glob("#{routerecord_data_dir}/*")
for rr_file in rr_file_list
  file_name = rr_file.split('/').last
  tr_file = "#{traceroute_data_dir}/#{file_name}"
  if File::exist?(tr_file)
    # read the traceroute file
    data = File.new(tr_file)
    path = parse_data_to_addr_list(data)
    tr_path = insert_traceroute_path(netdb, path)
    data.close
    # read the routerecord file
    data = File.new(rr_file)
    path = parse_data_to_addr_list(data)
    rr_path = insert_routerecord_path(netdb, path)
    data.close
    # correlate the two files
    correlate_tr_rr(netdb, tr_path, rr_path)
  end
end


if true
end

nmap_data_dir = 'data/nmap'
file_list = Dir::glob("#{nmap_data_dir}/*\.gnmap")
#file_list = Dir::glob("#{nmap_data_dir}/*\.csv")
for file in file_list
  data = File.new(file)
  addr_list = parse_data_to_addr_list(data)
  # delete the comments at the top and bottom
  addr_list.delete_at(0)
  addr_list.pop

  # delete the top 3 lines from the .csv file I dumped here
  #addr_list.delete_at(0)
  #addr_list.delete_at(0)
  #addr_list.delete_at(0)
  # insert all the listed hosts
  insert_addresses(netdb, addr_list)
  data.close
end


if true
#  # simulate parsing some arp tables and inserting them
#  insert_arp(netdb, "192.168.10.1", "00:04:5A:4B:9C:C3")
#  insert_arp(netdb, "192.168.10.254", "00:04:5A:4B:9C:C3")
#  insert_arp(netdb, "192.168.10.20", "00:04:5A:4B:9C:C3")
#  insert_arp(netdb, "192.168.10.21", "00:50:2C:04:BC:F9")
end

# Commit all the data we've loaded
netdb.transaction_commit



# Start a transaction for the optimizations and reduction logic.
netdb.transaction_begin

# test for later merging networks
#local_net = IPInterface.new("192.168.10.0/24")
#ip_id = netdb.insert_ip_network($cf_lack_of_proof, local_net)


# Commit the changes that have been made.
netdb.transaction_commit

puts ""
puts "Done processing input data"
puts ""



# Sanity constraints and optimizations
# The following function can be very computationally/IO expensive,
# so they are only run once before outputting the results.
# Some may also occasionally optimize results in the wrong way,
# so you may want to disable these in certain cases.

netdb.merge_ethernet_interfaces_by_mac_address



# Output result files
puts "Starting to write output files"

gxl_file = File.new("test.gxl", "w")
netdb.write_gxl(gxl_file)
gxl_file.write("\n")
gxl_file.close

dot_file = File.new("test.dot", "w")
netdb.write_graphviz(dot_file)
dot_file.close

puts "Done writing output files"
puts ""

netdb.disconnect


if false
  png_output_file = "network_big.png"
  # Covert the .dot file to a .png using GraphViz
  puts "Running 'neato' to generate #{png_output_file}"
  system("neato -v -Tpng -o #{png_output_file} test.dot")
  puts "Done\n"
end
