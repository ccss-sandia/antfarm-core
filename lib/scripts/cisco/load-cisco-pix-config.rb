#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

def print_help
  puts "Usage: antfarm [options] load-cisco-pix-config [options] [directories ...] [files ...]"
  puts "Options:"
  puts "  -t            Parse and create VPN tunnels only"
end

def parse(file)
  puts file

  hostname_regexp = /^hostname (\S+)/
  ip_addr_regexp = /^\s*ip address[\s\S]* ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3}) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  obj_grp_net_regexp = /^\s*object-group network (\S+)/
  net_obj_regexp = /^\s*network-object ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3}) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  net_obj_host_regexp = /^\s*network-object host ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  grp_obj_regexp = /^\s*group-object/

  # TODO: how to fill this array from command-line?
  obj_grp_nets_to_skip = Array.new

  hostname = nil
  fw_if_ips = Array.new
  net_obj_ips = Array.new
  net_obj_networks = Array.new

  capture_host = false

  list = File.open(file)

  list.each do |line|
    # Get hostname for PIX
    if name = hostname_regexp.match(line)
      hostname = name[1]
    end

    # Get IP addresses and netmasks for PIX interfaces
    if ip_addr = ip_addr_regexp.match(line)
      addr = ip_addr[1] + "/" + ip_addr[6]
      fw_if_ips << addr
    end

    # Get network object groups and hosts
#    if capture_host
#      if net_obj = net_obj_regexp.match(line)
#        addr = net_obj[1] + "/" + net_obj[6]
#        net_obj_networks << addr
#      elsif net_obj_host = net_obj_host_regexp.match(line)
#        net_obj_ips << net_obj_host[1]
#      elsif grp_obj = grp_obj_regexp.match(line)
#        # do nothing... read next line
#      else
#        if obj_grp_net = obj_grp_net_regexp.match(line)
#          network = obj_grp_net[1]
#
#          if obj_grp_nets_to_skip.include?(network)
#            capture_host = false
#          end
#        else
#          capture_host = false
#        end
#      end
#    else
#      if obj_grp_net = obj_grp_net_regexp.match(line)
#        network = obj_grp_net[1]
#
#        unless obj_grp_nets_to_skip.include?(network)
#          capture_host = true
#        end
#      end
#    end
  end

  list.close

  node = Node.create(:certainty_factor => 0.75, :name => hostname, :type => "FW") if hostname

  fw_if_ips.uniq!
  fw_if_ips.each do |address|
    ip_if = IpInterface.new :address => address
    if node
      ip_if.node = node
    else
      ip_if.node_type = "FW"
    end
    
    unless ip_if.save
      ip_if.errors.each_full do |msg|
        puts msg
      end
    end
  end

  net_obj_ips.uniq!
  net_obj_ips.each do |address|
    ip_if = IpInterface.new :address => address
    ip_if.node_type = "FWGRP"
    
    unless ip_if.save
      ip_if.errors.each_full do |msg|
        puts msg
      end
    end
  end

  net_obj_networks.uniq!
  net_obj_networks.each do |network|
    ip_net = IpNetwork.new :address => network
    
    unless ip_net.save
      ip_net.errors.each_full do |msg|
        puts msg
      end
    end
  end
end

def parse_routes(file)
  ip_regexp = /((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  route_regexp = Regexp.new('route (\S+) %s %s %s' % [ip_regexp, ip_regexp, ip_regexp])
end

def parse_tunnels(file)
  version_regexp = /^PIX Version ((\d+).(\d+)\((\d+)\))/
  nameif_ip_regexp = /^ip address (\S+) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  interface_regexp = /^interface/
  nameif_regexp = /^\s*nameif (\S+)/
  ipaddr_regexp = /^\s*ip address ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  crmap_addr_regexp = /^crypto map (\S+) [\s\S]* ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  crmap_if_regexp = /^crypto map (\S+) interface (\S+)/
  ip_addr_list = Array.new

  v6 = false
  v7 = false
  cap_if = false
  cap_crmap = false

  if_map = Hash.new
  if_name = nil

  cr_addr_map = Hash.new
  cr_if_map = Hash.new

  list = File.open(file)

  list.each do |line|
    if v6 == false && v7 == false
      if version = version_regexp.match(line)
        if version[2].to_i ==  6
          v6 = true
        elsif version[2].to_i ==  7
          v7 = true
        end
      end
    elsif v6 == true
      if nameif_ip = nameif_ip_regexp.match(line)
        if_map[nameif_ip[1]] = nameif_ip[2]
      end
    elsif v7 == true
      if cap_if == false
        if interface = interface_regexp.match(line)
          cap_if = true
        end
      else
        if nameif = nameif_regexp.match(line)
          cap_nameif = true
          if_name = nameif[1]
        elsif ipaddr = ipaddr_regexp.match(line)
          if_map[if_name] = ipaddr[1]
          cap_if = false
        end
      end
    end

    if crmap_addr = crmap_addr_regexp.match(line)
      unless cr_addr_map[crmap_addr[1]]
        cr_addr_map[crmap_addr[1]] = Array.new
      end

      cr_addr_map[crmap_addr[1]].push(crmap_addr[2])
    elsif crmap_if = crmap_if_regexp.match(line)
      cr_if_map[crmap_if[1]] = crmap_if[2]
    end
  end

  list.close

  cr_if_map.each do |key,value|
    ip_addr_list = cr_addr_map[key]
    ip_addr = if_map[value]

    source_ip_if = IpInterface.find_by_address(ip_addr)

    if source_ip_if
      ip_addr_list.each do |addr|
        target_ip_if = IpInterface.find_by_address(addr)

        if target_ip_if
          Traffic.create(:source_layer3_interface => source_ip_if.layer3_interface, :target_layer3_interface => target_ip_if.layer3_interface, :type => "Tunnel")
        end
      end
    end
  end
end

if ARGV[0] == '--help'
  print_help
else
  if ARGV.include?('-t')
    ARGV.delete('-t')
    ARGV.each do |arg|
      if File.directory?(arg)
        Find.find(arg) do |path|
          if File.file?(path)
            parse_tunnels(path)
          end
        end
      else
        parse_tunnels(arg)
      end
    end
  else
    ARGV.each do |arg|
      if File.directory?(arg)
        Find.find(arg) do |path|
          if File.file?(path)
            parse(path)
          end
        end
      else
        parse(arg)
      end
    end
  end
end
