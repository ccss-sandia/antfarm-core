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
