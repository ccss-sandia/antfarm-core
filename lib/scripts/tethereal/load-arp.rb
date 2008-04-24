#!/usr/bin/ruby -w

require 'antfarm'

require 'antfarm/layer2/ethernet'
require 'antfarm/layer3/ip'

require 'antfarm/simplify'


# Pull in DB username/password and other configuration settings
require 'antfarm-config.rb'


db = DBI.connect($dbname, $dblogin, $dbpasswd)
verbose = true

ethernet_if_table = Antfarm::Ethernet_Interface.new(db, verbose)
ip_if_table = Antfarm::IP_Interface.new(db, verbose)

arp_req_regexp = Regexp.new('([\w:]+) -> .+ ARP Who has .*\sTell ([\d\.]+)')

arp_cache = Array.new
list = File.open(ARGV[0])
list.each {|line|
  if m = arp_req_regexp.match(line)
    ethernet_addr = m[1]
    ip_addr = m[2]
    arp_cache.push("#{ip_addr} #{ethernet_addr}")
  end
}
list.close

arp_cache.uniq!.sort!
arp_cache.each {|entry|
  (ip_addr, ethernet_addr) = entry.split(' ')
  layer2_if_id = ethernet_if_table.insert(0.75, ethernet_addr)
  ip_if_table.insert(0.75, ip_addr, layer2_if_id)
}

ethernet_if_table.merge_by_mac_address

db.disconnect

# tethereal -n -r CITGO_051205_1414_IT 'arp' > CITGO_051205_1414_IT-arp.txt
# tethereal -n -r CITGO_051205_1414_IT 'ip' > CITGO_051205_1414_IT-ip.txt
