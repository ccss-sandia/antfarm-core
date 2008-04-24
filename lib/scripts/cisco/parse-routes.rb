#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

def print_help
  puts "Usage: antfarm [options] cisco [options] parse-routes [directories ...] [files ...]"
end

def parse(file)
  puts file

  hostname_regexp = Regexp.new('^hostname (\S+)')
  ipv4_regexp =     Regexp.new('((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
  route_regexp =    Regexp.new('^route (\S+) %s %s %s' % [ipv4_regexp, ipv4_regexp, ipv4_regexp])

  hostname = nil
  ip_addrs = Array.new

  list = File.open(file)

  list.each do |line|
    # Get hostname
    if name = hostname_regexp.match(line)
      hostname = name[1]
    end

    # Get routes
    if route = route_regexp.match(line)
      ip_addrs << route[12]
    end
  end

  node = Node.find_by_name(hostname)
  unless node.nil? || node.layer3_interfaces.nil?
    source_l3_iface = node.layer3_interfaces[0]

    ip_addrs.each do |ip_addr|
      target_l3_iface = Layer3Interface.interface_addressed(ip_addr)
      Traffic.create(:source_layer3_interface => source_l3_iface, :target_layer3_interface => target_l3_iface, :type => "Route") unless target_l3_iface.nil?
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
