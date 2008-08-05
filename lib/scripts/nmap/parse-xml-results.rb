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

require 'dbi'
require 'rexml/document'
require '/home/michael/Projects/security-tools/tool-db/common/common-tables'


class NmapDB

  def initialize(db)
    @db = db

    @host_state = Host_State.new(@db)
    @os_detection = OS_Detection.new(@db)
    @port_state = Port_State.new(@db)
    @service_detection = Service_Detection.new(@db)

    @ports_scanned = Hash.new

    # Query to insert a new row into the Nmap_Scan table
    nmap_scan_insert_str =  "INSERT INTO Nmap_Scan"
    nmap_scan_insert_str += " (tool_run_id, scan_type, protocol, services)"
    nmap_scan_insert_str += " VALUES"
    nmap_scan_insert_str += " (?, ?, ?, ?)"
    @nmap_scan_insert = @db.prepare(nmap_scan_insert_str)
  end


  def string_to_portlist(string)
    result = Array.new

    ranges = string.split(',')
    ranges.each {|range|
      (start, stop) = range.split('-')
      unless stop
        stop = start
      end
      for i in (start.to_i)..(stop.to_i)
        result.push(i)
      end
    }
    result.sort!
    result.uniq!

    return result
  end


  def load(io_handle)
    nmap_data = (REXML::Document.new(io_handle)).root
    nmap_data.elements.each("/nmaprun") {|nmaprun|
      unless nmaprun.attributes["xmloutputversion"] == "1.0"
        puts "Unknown XML version for nmap!!!!"
        # TODO: throw an error
      end

      vendor = "Fyodor"
      product = nmaprun.attributes["scanner"]
      version = nmaprun.attributes["version"]
      command_line = nmaprun.attributes["args"]
      puts "#{product} #{version}"
      puts "#{command_line}"

      tool_run = Tool_Run.new(@db, vendor, product, version)

      # The started/finished times in the Nmap XML files are in UNIX epoch time
      ts_fmt = "%Y-%m-%d %H:%M:%S %Z"
      time_started  = Time.at(nmaprun.attributes["start"].to_i)
      time_finished = Time.at(nmaprun.elements["runstats/finished"].attributes["time"].to_i)
      time_started_str  = time_started.strftime(ts_fmt)
      time_finished_str = time_finished.strftime(ts_fmt)

      puts "scan time: #{time_started_str} - #{time_finished_str}"

      # Insert Nmap run meta-data into DB
      tool_run_id = tool_run.insert(command_line, time_started, time_finished)

      # The types of scans performed and the proto/ports scanned
      nmaprun.elements.each("scaninfo") {|scaninfo|
        scan_type = scaninfo.attributes["type"]
        scan_protocol = scaninfo.attributes["protocol"]
        scan_services = scaninfo.attributes["services"]

        @nmap_scan_insert.execute(tool_run_id, scan_type, scan_protocol, scan_services)

        # Need to track this info since many ports are "scanned but not listed"
        # in all of Nmap's available output formats.
        @ports_scanned[scan_protocol] = string_to_portlist(scan_services)
      }

      # Process each host scanned
      nmaprun.elements.each("host") {|host|
        host_address = host.elements["address"].attributes["addr"]
        host_state = case host.elements["status"].attributes["state"]
                     when "up"
                       true
                     when "down"
                       false
                     else
                       nil
                     end
        host_certainty = 1.0

        # Insert host status into DB
        host_state_id = @host_state.insert(tool_run_id, host_address, host_state, host_certainty)

        puts "#{host_address}: #{host_state}"

        # Further processing only needs to be done for hosts that are "up"
        if host_state
          # Make a copy of @ports_scanned that can be worked on destructively for this host
          host_ports_scanned = Hash.new
          @ports_scanned.keys.each {|port_protocol|
            host_ports_scanned[port_protocol] = @ports_scanned[port_protocol].clone
          }

          extraports_state = case host.elements["ports/extraports"].attributes["state"]
                             when "open"
                               true
                             when "closed"
                               false
                             else
                               nil
                             end

          # Parse and handle ports explicitely listed in the file
          host.elements.each("ports/port") {|port|
            # Port information
            port_protocol = port.attributes["protocol"]
            port_number = port.attributes["portid"].to_i
            port_state = case port.elements["state"].attributes["state"]
                         when "open"
                           true
                         when "closed"
                           false
                         else
                           nil
                         end
            port_certainty = 0.9

            # This port was listed, so we don't need to handle it later
            host_ports_scanned[port_protocol].delete(port_number)

            print "\t#{port_number}/#{port_protocol}"

            # Insert port state into the DB
            port_state_id = @port_state.insert(host_state_id, port_protocol, port_number,
                                               port_state, port_certainty)

            # Only store service information for open ports
            if port_state
              service = port.elements["service"]
              service_name = service.attributes["name"]
              method = service.attributes["method"]
              service_certainty = 0.9 * ((service.attributes["conf"]).to_f / 10.0)

              service_product = service.attributes["product"]
              service_version = service.attributes["version"]
              service_extra_info = service.attributes["extrainfo"]

              service_str = ""
              if service_product
                service_str += "#{service_product}"
              end
              if service_version
                service_str += " #{service_version}"
              end
              if service_extra_info
                service_str += " #{service_extra_info}"
              end

              print " [#{service_name}: #{service_product} #{service_version} #{service_extra_info}]"
              print " (#{method}:#{service_certainty})"

              # Insert detected service into the DB
              @service_detection.insert(port_state_id,
                                        service_name, service_str, service_certainty)
            end

            print "\n"
          }

          # Handle extra ports that are "scanned but not listed"
          host_ports_scanned.keys.each {|port_protocol|
            host_ports_scanned[port_protocol].each {|port_number|
              # Insert port state into the DB
              port_certainty = 0.9
              port_state_id = @port_state.insert(host_state_id, port_protocol, port_number,
                                                 extraports_state, port_certainty)              
            }
          }


          # Parse and handle OS identification
          host.elements.each("os/osclass") {|os|
            os_vendor = os.attributes["vendor"]
            os_family = os.attributes["osfamily"]
            os_gen = os.attributes["osgen"]
            os_certainty = 0.9 * ((os.attributes["accuracy"]).to_f / 100.0)

            puts "#{os_vendor}: #{os_family} #{os_gen} (certainty: #{os_certainty})"

            # Insert detected OS into the DB
            @os_detection.insert(host_state_id,
                                 os_vendor, os_family, os_gen, os_certainty)
          }
          host.elements.each("os/osmatch") {|os|
            os_match = os.attributes["name"]
            os_certainty = 0.9 * ((os.attributes["accuracy"]).to_f / 100.0)

            puts "#{os_match} (certainty: #{os_certainty})"
          }

          puts ""
        end
      }  # end nmaprun block
    }  # end nmap_data block
  end

end  # class NmapDB

