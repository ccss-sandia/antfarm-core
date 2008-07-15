#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

def print_help
  puts "Usage: antfarm [options] cisco [options] parse-network-objects [directories ...] [files ...]"
  puts
  puts "This script parses a Cisco IOS configuration file, creating a new IP Interface for each"
  puts "network object host specified."
end

def parse(file)
  puts file

  net_obj_host_regexp = Regexp.new('^\s*network-object host ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')

  net_obj_hosts = Array.new

  list = File.open(file)

  list.each do |line|
    # Get network object hosts
    if net_obj_host = net_obj_host_regexp.match(line)
      net_obj_hosts << net_obj_host[1]
    end
  end

  list.close

  net_obj_hosts.uniq!
  net_obj_hosts.each do |address|
    if Layer3Network.network_containing(address)
      ip_iface = IpInterface.new :address => address
      ip_iface.node_name = address
      ip_iface.node_device_type = "HOST"
      
      unless ip_iface.save
        ip_iface.errors.each_full do |msg|
          puts msg
        end
      end
    end
  end
end

if ARGV[0] == '--help'
  print_help
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

