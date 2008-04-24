#!/usr/bin/ruby

def print_help
  puts "Usage: antfarm [options] load-host <host file>"
  puts
  puts "The host file should contain a list of host"
  puts "IP addresses, one per line."
end

def parse(file)
  begin
    list = File.open(file)
  rescue Errno::ENOENT
    puts "The file '#{file}' does not exist"
    exit
  end

  list.each do |line|
    IpInterface.create :address => line.strip
  end
end

if ARGV.empty? || ARGV.length > 1 || ARGV[0] == '--help'
  print_help
else
  parse(ARGV[0])
end

