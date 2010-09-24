module Antfarm
  module Plugin
    module Cisco
      class FileDoesNotExistError < Antfarm::AntfarmError; end

      class ParsePixConfig
        include Antfarm::Plugin

        def initialize
          super({ :name   => 'Parse PIX Firewall Config',
                  :desc   => 'Parses a Cisco PIX IOS config file',
                  :author => 'Bryan T. Richardson <btricha>' },
                [ { :name     => :input,
                    :desc     => 'Cisco PIX IOS config file or directory',
                    :type     => String,
                    :required => true },
                  { :name     => :tunnels,
                    :desc     => 'Only parse IPSec Tunnels',
                    :required => false }
                ])
        end

        def run(options)
          input   = options[:input]
          tunnels = options[:tunnels]

          if File.directory?(input)
            Find.find(input) do |path|
              if File.file?(path)
                if tunnels
                  parse_tunnels(path)
                else
                  parse(path)
                end
              end
            end
          else
            if tunnels
              parse_tunnels(input)
            else
              parse(input)
            end
          end
        end

        def parse(file)
          print_message "Parsing file #{file}"

          begin
            hostname_regexp     = %r{^hostname (\S+)}
            ip_addr_regexp      = %r{^\s*ip address[\s\S]* ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3}) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})}
            obj_grp_net_regexp  = %r{^\s*object-group network (\S+)}
            net_obj_regexp      = %r{^\s*network-object ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3}) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})}
            net_obj_host_regexp = %r{^\s*network-object host ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})}
            grp_obj_regexp      = %r{^\s*group-object}

            # TODO: how to fill this array from command-line?
            obj_grp_nets_to_skip = Array.new

            hostname         = nil
            fw_if_ips        = Array.new
            net_obj_ips      = Array.new
            net_obj_networks = Array.new

            capture_host = false

            File.open(file) do |list|
              list.each do |line|
                # Get hostname for PIX
                if name = hostname_regexp.match(line)
                  hostname = name[1]
                end

                # Get IP addresses and netmasks for PIX interfaces
                if ip_addr = ip_addr_regexp.match(line)
                  addr = ip_addr[1] + "/" + ip_addr[6]
                  fw_if_ips << addr
                end
              end
            end

            fw_if_ips.uniq!
            fw_if_ips.each do |address|
              ip_if = Antfarm::Model::IpInterface.new :address => address
              ip_if.node_name = hostname
              ip_if.node_device_type = 'FW'
              unless ip_if.save
                ip_if.errors.each_full do |msg|
                  print_error msg
                end
              end
            end

            net_obj_ips.uniq!
            net_obj_ips.each do |address|
              ip_if = Antfarm::Model::IpInterface.new :address => address
              ip_if.node_device_type = 'FW NW OBJECT'
              unless ip_if.save
                ip_if.errors.each_full do |msg|
                  print_error msg
                end
              end
            end

            net_obj_networks.uniq!
            net_obj_networks.each do |network|
              ip_net = Antfarm::Model::IpNetwork.new :address => network
              unless ip_net.save
                ip_net.errors.each_full do |msg|
                  print_error msg
                end
              end
            end
          rescue Errno::ENOENT
            raise FileDoesNotExistError, "The file #{file} doesn't exist"
          rescue Exception => e
            raise Antfarm::AntfarmError, e.message
          end
        end

        def parse_tunnels(file)
          print_message "Parsing file #{file}"

          begin
            version_regexp    = %r{^PIX Version ((\d+).(\d+)\((\d+)\))}
            nameif_ip_regexp  = %r{^ip address (\S+) ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})}
            interface_regexp  = %r{^interface}
            nameif_regexp     = %r{^\s*nameif (\S+)}
            ipaddr_regexp     = %r{^\s*ip address ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})}
            crmap_addr_regexp = %r{^crypto map (\S+) [\s\S]* ((\d){1,3}\.(\d){1,3}\.(\d){1,3}\.(\d){1,3})}
            crmap_if_regexp   = %r{^crypto map (\S+) interface (\S+)}
            ip_addr_list      = Array.new

            v6        = false
            v7        = false
            cap_if    = false
            cap_crmap = false

            if_map  = Hash.new
            if_name = nil

            cr_addr_map = Hash.new
            cr_if_map   = Hash.new

            File.open(file) do |list|
              list.each do |line|
                if v6 == false && v7 == false
                  if version = version_regexp.match(line)
                    if version[2].to_i ==  6
                      v6 = true
                    elsif version[2].to_i ==  7
                      v7 = true
                    end
                  end
                elsif v6 == true
                  if nameif_ip = nameif_ip_regexp.match(line)
                    if_map[nameif_ip[1]] = nameif_ip[2]
                  end
                elsif v7 == true
                  if cap_if == false
                    if interface = interface_regexp.match(line)
                      cap_if = true
                    end
                  else
                    if nameif = nameif_regexp.match(line)
                      cap_nameif = true
                      if_name = nameif[1]
                    elsif ipaddr = ipaddr_regexp.match(line)
                      if_map[if_name] = ipaddr[1]
                      cap_if = false
                    end
                  end
                end

                if crmap_addr = crmap_addr_regexp.match(line)
                  unless cr_addr_map[crmap_addr[1]]
                    cr_addr_map[crmap_addr[1]] = Array.new
                  end

                  cr_addr_map[crmap_addr[1]].push(crmap_addr[2])
                elsif crmap_if = crmap_if_regexp.match(line)
                  cr_if_map[crmap_if[1]] = crmap_if[2]
                end
              end
            end

            cr_if_map.each do |key,value|
              ip_addr_list = cr_addr_map[key]
              ip_addr      = if_map[value]

              source_ip_if = Antfarm::Model::IpInterface.find_by_address(ip_addr)

              if source_ip_if
                ip_addr_list.each do |addr|
                  target_ip_if = Antfarm::Model::IpInterface.find_by_address(addr)

                  if target_ip_if
  #                 Traffic.create(:source_layer3_interface => source_ip_if.layer3_interface, :target_layer3_interface => target_ip_if.layer3_interface, :description => 'TUNNEL')
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
