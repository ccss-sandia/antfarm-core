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

ip_src_dst_regexp = Regexp.new('([\d\.]+) -> ([\d\.]+)')

ip_addr_list = Array.new
list = File.open(ARGV[0])
list.each {|line|
  if m = ip_src_dst_regexp.match(line)
    ip_src_addr = m[1]
    ip_dst_addr = m[2]
    ip_addr_list.push(ip_src_addr)
    ip_addr_list.push(ip_dst_addr)
  end
}
list.close

ip_addr_list.uniq!.sort!
ip_addr_list.each {|ip_addr|
  #puts "'#{ip_addr}'"
  ip_if_table.insert(0.75, ip_addr)
}

db.disconnect

# tethereal -n -r CITGO_051205_1414_IT 'arp' > CITGO_051205_1414_IT-arp.txt
# tethereal -n -r CITGO_051205_1414_IT 'ip and ip.dst_host != 146.146.167.255 and not (ip.host >= 224.0.0.0 and ip.host <= 224.255.255.255)' > CITGO_051205_1414_IT-ip.txt
