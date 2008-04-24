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
layer2_if_table = Antfarm::Layer2_Interface.new(db, verbose)
ip_if_table = Antfarm::IP_Interface.new(db, verbose)

list = File.open(ARGV[0])

router_name = list.readline.strip!
new_node_id = node_table.insert(0.75, router_name)

list.each {|line|
  ip_addr = line
  ip_addr.strip!

  ip_if_id = ip_if_table.insert(0.75, ip_addr)
  # Get Node associated with the IP
  layer2_if_id = ip_if_table.layer2_interface_having(ip_if_id)
  node_id = layer2_if_table.node_having(layer2_if_id)
  # Merge the default anonymous node_id with the new router node_id
  node_table.merge(new_node_id, node_id)
}
list.close

db.disconnect
