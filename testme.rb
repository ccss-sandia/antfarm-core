require 'pcap'

# Must be done before environment.rb is loaded or
# ANTFARM_ENV will get overwritten by boot.rb.
# ANTFARM_ENV = 'test'

require 'config/environment'

require 'antfarm'
require 'ethernet_interface'
require 'ip_interface'
require 'ip_network'
require 'traffic'

#node = Antfarm::Node.new :certainty_factor => 0.75
#node.type = "Firewall"
#unless node.save
#  node.errors.each_full do |msg|
#    puts msg
#  end
#end

#node = Antfarm::Node.find(1)
#l2_if = Antfarm::Layer2Interface.new :certainty_factor => 0.75
#l2_if.node = node
#unless l2_if.save
#  l2_if.errors.each_full do |msg|
#    puts msg
#  end
#end

#Antfarm::Node.create :certainty_factor => 0.65, :name => "hello"
#Antfarm::Node.create :certainty_factor => 0.65, :name => "hello"

cap = Pcap::Capture.open_offline(ARGV[0])
cap.each do |pkt|
  if pkt.ip?
    puts pkt.src.to_num_s
  end
end

#cap = Pcap::Capture.open_offline(ARGV[0])
#cap.each do |pkt|
#  if pkt.ip?
#    from_if = Antfarm::IPInterface.new :address => pkt.src.to_num_s
#    to_if = Antfarm::IPInterface.new :address => pkt.dst.to_num_s

#    unless from_if.save
#      from_if.errors.each_full do |msg|
#        puts msg
#      end
#    end

#    unless to_if.save
#      to_if.errors.each_full do |msg|
#        puts msg
#      end
#    end

#    from_l3_if = Antfarm::Layer3Interface.interface_addressed(from_if.address)
#    to_l3_if = Antfarm::Layer3Interface.interface_addressed(to_if.address)
#    port = pkt.dport if pkt.ip_proto == Antfarm::TCP_PROTO || pkt.ip_proto == Antfarm::UDP_PROTO

#    Antfarm::Traffic.add(from_l3_if, to_l3_if, port, "Test")
#  end
#end

#ip_if = IpInterface.new :address => "192.168.0.101"
#unless ip_if.save
#  ip_if.errors.each_full do |msg|
#    puts msg
#  end
#end

#eth_if = EthernetInterface.new :address => "00:09:6A:DF:FE:42"
#unless eth_if.save
#  eth_if.errors.each_full do |msg|
#    puts msg
#  end
#end
