#!/usr/bin/ruby -w

require 'antfarm'

require 'antfarm/layer2/ethernet'
require 'antfarm/layer3/ip'

require 'antfarm/simplify'

# Pull in DB username/password and other configuration settings
require 'antfarm-config.rb'


db = DBI.connect($dbname, $dblogin, $dbpasswd)
verbose = true

node_table = Antfarm::Node.new(db)
ethernet_if_table = Antfarm::Ethernet_Interface.new(db, verbose)
ip_if_table = Antfarm::IP_Interface.new(db, verbose)

list = File.open(ARGV[0])

router_name = list.readline.strip!
node_id = node_table.insert(0.75, router_name)

list.each {|line|
  (ethernet_addr, ip_addr) = line.split(' ')
  ethernet_addr.strip!
  ip_addr.strip!

  layer2_if_id = ethernet_if_table.insert(0.75, ethernet_addr, node_id)
  ip_if_table.insert(0.75, ip_addr, layer2_if_id)
}
list.close

ethernet_if_table.merge_by_mac_address

db.disconnect
