#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

def print_help
  puts "Usage: antfarm [options] cisco [options] parse-ip-ifaces [directories ...] [files ...]"
  puts
  puts "This script parses one or more Cisco PIX firewall configuration files and creates"
  puts "an IP Interface object for each interface using the IP address configured.  Currently,"
  puts "only versions 7.6 and 7.7 of the PIX IOS are supported."
end

def parse(file)
  puts file

  pix_version_regexp =    Regexp.new('^PIX Version ((\d+)\.(\d+)\((\d+)\))')
  hostname_regexp =       Regexp.new('^hostname (\S+)')
  iface_regexp =          Regexp.new('^interface')
  ipv4_regexp =           Regexp.new('((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
  ip_addr_regexp =        Regexp.new('^ip address (\S+) %s %s' % [ipv4_regexp, ipv4_regexp])
  iface_ip_addr_regexp =  Regexp.new('^\s*ip address %s %s' % [ipv4_regexp, ipv4_regexp])

  pix_version = nil
  hostname = nil
  iface_ips = Array.new
  capture_iface = false

  list = File.open(file)

  list.each do |line|
    # Get PIX IOS version
    unless pix_version
      if version = pix_version_regexp.match(line)
        pix_version = version[2].to_i
      end
    end

    # Get hostname
    unless hostname
      if name = hostname_regexp.match(line)
        hostname = name[1]
      end
    end
    
    # Get interface IP addresses
    if pix_version == 6
      if ip_addr = ip_addr_regexp.match(line)
        iface_ips << "#{ip_addr[2]}/#{ip_addr[7]}"
      end
    elsif capture_iface
      if line.strip! == "!"
        capture_iface = false
      else
        if ip_addr = iface_ip_addr_regexp.match(line)
          iface_ips << "#{ip_addr[1]}/#{ip_addr[6]}"
          capture_iface = false
        end
      end
    else
      if iface = iface_regexp.match(line)
        capture_iface = true
      end
    end
  end

  list.close

  iface_ips.uniq!
  iface_ips.each do |address|
    ip_iface = IpInterface.new :address => address
    ip_iface.node_name = hostname if hostname
    ip_iface.node_device_type = "Layer 3 Device"
    
    unless ip_iface.save
      ip_iface.errors.each_full do |msg|
        puts msg
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

