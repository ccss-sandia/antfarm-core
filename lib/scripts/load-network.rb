#!/usr/bin/ruby

def print_help
  puts "Usage: antfarm [options] load-network"
end

def parse
  network_list =
    ['146.146.112.0/22',
     '146.146.150.0/23']

  network_list.each do |network|
    IpNetwork.create(:address => network.strip)
  end
end

if ARGV.empty?
  parse
elsif ARGV[0] == '--help'
  print_help
end
