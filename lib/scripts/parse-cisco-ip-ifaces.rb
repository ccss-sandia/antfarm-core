#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

require 'find'
require 'ip_interface'
require 'node'

def print_help
  puts "Usage: antfarm [options] parse-cisco-ip-ifaces [directories ...] [files ...]"
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

  node = Node.create(:certainty_factor => 0.75, :name => hostname, :type => "Layer 3 Device") if hostname

  iface_ips.uniq!
  iface_ips.each do |address|
    ip_iface = IpInterface.new :address => address
    if node
      ip_iface.node = node
    else
      ip_iface.node_type = "Layer 3 Device"
    end
    
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
