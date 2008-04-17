#!/usr/bin/ruby

def print_help
  puts "Usage: antfarm [options] load-cisco-arp [directories ...] [files ...]"
end

def parse(file)
  list = File.open(file)

  list.each do |line|
    (junk, ip_addr, ethernet_addr) = line.split(' ')
    ip_addr.strip!
    ethernet_addr.strip!

    IpInterface.create(:address => ip_addr, :ethernet_address => ethernet_addr)
  end

  list.close

  # TODO: merge by ethernet address
end

if ARGV[0] == '--help'
  print_help
else
  ARGV.each do |arg|
    if File.directory?(arg)
      Find.find(arg) do |path|
        if File.file?(path)
          parse(path)
        end
      end
    else
      parse(arg)
    end
  end
end