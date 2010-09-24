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

      class ParseNetworkObjects
        include Antfarm::Plugin

        def initialize
          super({ :name   => 'Parse Network Objects',
                  :desc   => 'Parses a Cisco IOS config file and creates an IP Interface for each network object',
                  :author => 'Bryan T. Richardson <btricha>' },
                [ { :name     => :input,
                    :desc     => 'Cisco IOS config file or directory',
                    :type     => String,
                    :required => true }
                ])
        end

        def run(options)
          input = options[:input]

          if File.directory?(input)
            Find.find(input) do |path|
              if File.file?(path)
                parse(path)
              end
            end
          else
            parse(input)
          end
        end

        def parse(file)
          print_message "Parsing file #{file}"

          begin
            net_obj_host_regexp = Regexp.new('^\s*network-object host ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})')

            net_obj_hosts = Array.new

            File.open(file) do |list|
              list.each do |line|
                # Get network object hosts
                if net_obj_host = net_obj_host_regexp.match(line)
                  net_obj_hosts << net_obj_host[1]
                end
              end
            end

            net_obj_hosts.uniq!
            net_obj_hosts.each do |address|
              if Antfarm::Model::LayerThreeNetwork.network_containing(address)
                ip_iface                  = Antfarm::Model::IpInterface.new :address => address
                ip_iface.node_name        = address
                ip_iface.node_device_type = "HOST"
                
                unless ip_iface.save
                  ip_iface.errors.each_full do |msg|
                    print_error msg
                  end
                end
              end
            end
          rescue Errno::ENOENT
            raise FileDoesNotExistError, "The file #{file} doesn't exist"
          rescue Exception => e
            raise Antfarm::AntfarmError, e.message
          end
        end
      end
    end
  end
end
