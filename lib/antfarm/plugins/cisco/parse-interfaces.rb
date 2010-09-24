################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

module Antfarm
  module Plugin
    module Cisco
      class FileDoesNotExistError < Antfarm::AntfarmError; end

      class ParseInterfaces
        include Antfarm::Plugin

        def initialize
          super({ :name   => 'Parse Interfaces',
                  :desc   => 'Parse Cisco IOS configuration file, looking for IP interfaces',
                  :author => 'Bryan T. Richardson <btricha>' },
                [ { :name     => :input_file,
                    :desc     => 'Cisco IOS config file',
                    :type     => String,
                    :required => true }
                ])
        end

        def run(options)
          print_message "Parsing file #{options[:input_file]}"

          begin
            pix_version_regexp   = Regexp.new('^PIX Version ((\d+)\.(\d+)\((\d+)\))')
            hostname_regexp      = Regexp.new('^hostname (\S+)')
            iface_regexp         = Regexp.new('^interface')
            ipv4_regexp          = Regexp.new('((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')
            ip_addr_regexp       = Regexp.new('^ip address (\S+) %s %s' % [ipv4_regexp, ipv4_regexp])
            iface_ip_addr_regexp = Regexp.new('^\s*ip address %s %s' % [ipv4_regexp, ipv4_regexp])

            pix_version   = nil
            hostname      = nil
            iface_ips     = Array.new
            capture_iface = false

            File.open(options[:input_file]) do |file|
              file.each do |line|
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
            end

            iface_ips.uniq!
            iface_ips.each do |address|
              ip_iface = Antfarm::Model::IpInterface.new :address => address
              ip_iface.node_name = hostname if hostname
              ip_iface.node_device_type = "Layer 3 Device"
              
              unless ip_iface.save
                ip_iface.errors.each_full do |msg|
                  print_error msg
                end
              end
            end
          rescue Errno::ENOENT
            raise FileDoesNotExistError, "The file '#{options[:input_file]}' doesn't exist"
          rescue Exception => e
            raise Antfarm::AntfarmError, e.message
          end
        end
      end
    end
  end
end
