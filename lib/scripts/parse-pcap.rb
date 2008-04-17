#! /usr/bin/ruby

require 'pcap'

cap = Pcap::Capture.open_offline(ARGV[0])
cap.each do |pkt|
  if pkt.ip?
    source_ip_addr = pkt.src.to_num_s
    target_ip_addr = pkt.dst.to_num_s

    source_l3_net = Layer3Network.network_containing(source_ip_addr)
    target_l3_net = Layer3Network.network_containing(target_ip_addr)

    if source_l3_net && target_l3_net
      puts "Added traffic -- #{source_ip_addr} ==> #{target_ip_addr}"

      source_ip_iface = IpInterface.create :address => source_ip_addr, :layer3_network => source_l3_net, :node_type => "PCAP"
      target_ip_iface = IpInterface.create :address => target_ip_addr, :layer3_network => target_l3_net, :node_type => "PCAP"

      Traffic.create :source_layer3_interface => source_ip_iface.layer3_interface, \
                     :target_layer3_interface => target_ip_iface.layer3_interface, \
                     :type => "PCAP"
    end
  end
end
