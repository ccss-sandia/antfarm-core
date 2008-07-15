#!/usr/bin/ruby

def print_help
  puts "Usage: antfarm [options] load-network <network file>"
  puts
  puts "The network file should contain a list of IP"
  puts "network addresses, one per line."
end

# Parses the given file, creating an IP Interface for
# each IP address.
def parse(file)
  begin
    list = File.open(file)
  rescue Errno::ENOENT
    puts "The file '#{file}' does not exist"
    exit
  end

  list.each do |line|
    IpNetwork.create :address => line.strip
  end
end

if ARGV.empty? || ARGV.length > 1 || ARGV[0] == '--help'
  print_help
else
  parse(ARGV[0])
end

