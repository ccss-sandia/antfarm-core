#! /usr/bin/ruby

require 'pcap'

def print_help
  puts "Usage: antfarm [options] pcap [options] parse-pcap-file <pcap file>"
  puts
  puts "This script parses a libPcap file containing traffic capture data,"
  puts "creating an IP interface for each endpoint and a traffic object"
  puts "for the traffic between them.  Node device types are set to 'PCAP',"
  puts "as well as traffic descriptions."
end

def parse(file)
  cap = Pcap::Capture.open_offline(ARGV[0])
  cap.each do |pkt|
    if pkt.ip?
      source_ip_addr = pkt.src.to_num_s
      target_ip_addr = pkt.dst.to_num_s

      source_l3_net = Layer3Network.network_containing(source_ip_addr)
      target_l3_net = Layer3Network.network_containing(target_ip_addr)

      if source_l3_net && target_l3_net
        puts "Added traffic -- #{source_ip_addr} ==> #{target_ip_addr}"

        source_ip_iface = IpInterface.create :address => source_ip_addr, :layer3_network => source_l3_net, :node_device_type => "PCAP"
        target_ip_iface = IpInterface.create :address => target_ip_addr, :layer3_network => target_l3_net, :node_device_type => "PCAP"

        Traffic.create :source_layer3_interface => source_ip_iface.layer3_interface, \
                       :target_layer3_interface => target_ip_iface.layer3_interface, \
                       :description => "PCAP"
      end
    end
  end
end

if ARGV.empty? || ARGV.length > 1 || ARGV[0] == '--help'
  print_help
else
  parse(ARGV[0])
end

