#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

# TODO: Incomplete!!!  Need to look at PIX Version 7 config files.

def print_help
  puts "Usage: antfarm [options] parse-cisco-pix-tunnels [directories ...] [files ...]"
end

def parse(file)
  puts file

  pix_version_regexp =    Regexp.new('^PIX Version ((\d+)\.(\d+)\((\d+)\))')
  iface_regexp =          Regexp.new('^interface')
  ipv4_regexp =           Regexp.new('((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
  ip_addr_regexp =        Regexp.new('^ip address (\S+) %s %s' % [ipv4_regexp, ipv4_regexp])
  iface_ip_addr_regexp =  Regexp.new('^\s*ip address %s %s' % [ipv4_regexp, ipv4_regexp])

  nameif_ip_regexp = /^ip address (\S+) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  interface_regexp = /^interface/
  nameif_regexp = /^\s*nameif (\S+)/
  ipaddr_regexp = /^\s*ip address ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  crmap_addr_regexp = /^crypto map (\S+) [\s\S]* ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})/
  crmap_if_regexp = /^crypto map (\S+) interface (\S+)/
  ip_addr_list = Array.new

  pix_version = nil
  capture_iface = false
  capture_crmap = false

  iface_map = Hash.new
  iface_name = nil

  cr_addr_map = Hash.new
  cr_iface_map = Hash.new

  list = File.open(file)

  list.each do |line|
    # Get PIX IOS version
    unless pix_version
      if version = pix_version_regexp.match(line)
        pix_version = version[2].to_i
      end
    end

    if pix_version == 6
      if ip_addr = ip_addr_regexp.match(line)
        iface_map[ip_addr[1]] = ip_addr[2]
      end
    elsif pix_version == 7 
      if capture_iface == false
        if iface = iface_regexp.match(line)
          capture_iface = true
        end
      else
        if nameif = nameif_regexp.match(line)
          iface_name = nameif[1]
        elsif ip_addr = ip_addr_regexp.match(line)
          iface_map[iface_name] = ip_addr[1]
          capture_iface = false
        end
      end
    end

    if crmap_addr = crmap_addr_regexp.match(line)
      unless cr_addr_map[crmap_addr[1]]
        cr_addr_map[crmap_addr[1]] = Array.new
      end

      cr_addr_map[crmap_addr[1]].push(crmap_addr[2])
    elsif crmap_iface = crmap_iface_regexp.match(line)
      cr_iface_map[crmap_iface[1]] = crmap_iface[2]
    end
  end

  list.close

  cr_iface_map.each do |key,value|
    ip_addr_list = cr_addr_map[key]
    ip_addr = iface_map[value]

    source_ip_iface = IpInterface.find_by_address(ip_addr)

    if source_ip_iface
      ip_addr_list.each do |addr|
        target_ip_iface = IpInterface.find_by_address(addr)

        if target_ip_iface
          Traffic.create(:source_layer3_interface => source_ip_if.layer3_interface, :target_layer3_interface => target_ip_if.layer3_interface, :type => "Tunnel")
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
