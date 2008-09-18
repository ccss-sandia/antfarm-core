#!/usr/bin/env ruby

# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Michael Berg, Sandia National Laboratories <mjberg@sandia.gov>
# Modified By: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 

def print_help
  puts "Usage: antfarm [options] nmap [options] parse-xml [directories ...] [files ...]"
  puts
  puts "This script parses one or more Nmap xml-formatted output files and creates"
  puts "an IP Interface object for each host detected."
end

def string_to_portlist(string)
  result = Array.new
  ranges = string.split(',')
  ranges.each do |range|
    (start, stop) = range.split('-')
    unless stop
      stop = start
    end
    for i in (start.to_i)..(stop.to_i)
      result.push(i)
    end
  end
  result.sort!
  result.uniq!
  result.flatten!
  return result
end

def parse(file)
  puts file
  results = REXML::Document.new(File.new(file))
  results.elements.each('nmaprun') do |scan|
    action = Action.new
    action.tool        = scan.attributes['scanner']
    action.description = scan.attributes['args']
    action.start       = scan.attributes['startstr']
    action.end         = scan.elements['runstats/finished'].attributes['timestr']
    action.save false
    scanned_ports = Hash.new
    scan.elements.each("scaninfo") do |info|
      type = info.attributes["type"]
      protocol = info.attributes["protocol"]
      services = info.attributes["services"]
      # Need to track this info since many ports are "scanned but not listed"
      # in all of Nmap's available output formats.
      scanned_ports[protocol] = string_to_portlist(services)
    end
    scan.elements.each('host') do |host|
      host_state = host.elements['status'].attributes['state']
      interface = IpInterface.create :address => host.elements['address'].attributes['addr']
      host.elements.each('hostnames/hostname') do |hostname|
        DnsEntry.create :address  => host.elements['address'].attributes['addr'],
                        :hostname => hostname.attributes['name']
      end
      if host_state == 'up'
        host_scanned_ports = scanned_ports.dup # does this create a separate hash?
        host.elements.each("ports/port") do |port|
          protocol = port.attributes["protocol"]
          number = port.attributes["portid"].to_i
          port_state = port.elements["state"].attributes["state"]

          # This port was listed, so we don't need to handle it later
          host_scanned_ports[protocol].delete(number)

          # Only store service information for open ports
          if port_state == 'open'
            port_service = port.elements['service']
            service = Service.new
            service.node             = interface.layer3_interface.layer2_interface.node
            service.action           = action
            service.protocol         = protocol
            service.port             = number
            service.name             = port_service.attributes['name']
            service.certainty_factor = 0.9 * ((port_service.attributes["conf"]).to_f / 10.0)
            service.save false
          end
        end

        # Handle extra ports that are "scanned but not listed" if state is open
        if host.elements['ports/extraports'] && host.elements['ports/extraports'].attributes['state'] == 'open'
          host_scanned_ports.each do |protocol,number|
            service = Service.new
            service.node             = interface.layer3_interface.layer2_interface.node
            service.action           = action
            service.protocol         = protocol
            service.port             = number
            service.certainty_factor = 0.9
            service.save false
          end 
        end

        if host.elements['os/osfingerprint']
          os = OperatingSystem.new
          os.node             = interface.layer3_interface.layer2_interface.node
          os.action           = action
          os.fingerprint      = host.elements['os/osfingerprint'].attributes['fingerprint']
          os.certainty_factor = 0.9
          os.save false
        end

        host.elements.each('trace/hop') do |hop|
          IpInterface.create :address => hop.attributes['ipaddr']
          if hop.attributes['host']
            DnsEntry.create :address  => hop.attributes['ipaddr'],
                            :hostname => hop.attributes['host']
          end
        end
      end
    end
  end
end

if ['-h', '--help'].include?(ARGV[0])
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
