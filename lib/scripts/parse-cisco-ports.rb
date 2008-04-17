#!/usr/bin/env ruby

# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>

def print_help
  puts "Usage: antfarm [options] parse-cisco-ports tcp|udp [directories ...] [files ...]"
end

def parse(file, proto, port_hash)
  puts file

  acl_tcp_eq_regexp =    Regexp.new('[\s\S]*permit tcp [\s\S]* eq ([\d\w]*)')
  acl_tcp_est_regexp =   Regexp.new('[\s\S]*permit tcp [\s\S]* established')
  acl_tcp_range_regexp = Regexp.new('[\s\S]*permit tcp [\s\S]* range (\d+) (\d+)')

  acl_udp_eq_regexp =    Regexp.new('[\s\S]*permit udp [\s\S]* eq ([\d\w]*)')
  acl_udp_est_regexp =   Regexp.new('[\s\S]*permit udp [\s\S]* established')
  acl_udp_range_regexp = Regexp.new('[\s\S]*permit udp [\s\S]* range (\d+) (\d+)')

# port_hash = Hash.new

  list = File.open(file)

  list.each do |line|
    if proto == 'tcp'
      if acl_tcp_eq = acl_tcp_eq_regexp.match(line)
        port = acl_tcp_eq[1]
        if port_hash.key?(port)
          port_hash[port] += 1
        else
          port_hash[port] = 1
        end
      elsif acl_tcp_range = acl_tcp_range_regexp.match(line)
        (acl_tcp_range[1]..acl_tcp_range[2]).each do |port|
          if port_hash.key?(port)
            port_hash[port] += 1
          else
            port_hash[port] = 1
          end
        end
      end
    elsif proto == 'udp'
      if acl_udp_eq = acl_udp_eq_regexp.match(line)
        port = acl_udp_eq[1]
        if port_hash.key?(port)
          port_hash[port] += 1
        else
          port_hash[port] = 1
        end
      elsif acl_udp_range = acl_udp_range_regexp.match(line)
        (acl_udp_range[1]..acl_udp_range[2]).each do |port|
          if port_hash.key?(port)
            port_hash[port] += 1
          else
            port_hash[port] = 1
          end
        end
      end
    end
  end

# port_hash.each_pair do |key,value|
#   puts "#{key} ==> #{value}"
# end

  list.close

  return port_hash
end

if ARGV.empty? || ARGV[0] == '--help'
  print_help
else
  option = ARGV.shift
  port_hash = Hash.new

  ARGV.each do |arg|
    if File.directory?(arg)
      Find.find(arg) do |path|
        if File.file?(path)
          port_hash = parse(path, option, port_hash)
        end
      end
    else
      port_hash = parse(arg, option, port_hash)
    end
  end

  ports = port_hash.sort { |a,b| a[0].to_i <=> b[0].to_i }
# ports.each do |port|
#   puts "#{port[0]} ==> #{port[1]}"
# end

  # TODO: Clean up the code below... it's very ugly!!!
  range_array = Array.new
  final_array = Array.new

  while !ports.empty?
    if range_array.empty? || ports.first[0].to_i == range_array.last.to_i + 1
      range_array << ports.shift[0]
    else
      if range_array.length == 1
        final_array << range_array.first
      else
        final_array << "#{range_array.first}-#{range_array.last}"
      end

      range_array.clear
    end
  end

  unless range_array.empty?
    if range_array.length == 1
      final_array << range_array.first
    else
      final_array << "#{range_array.first}-#{range_array.last}"
    end
  end

  result = nil
  final_array.each do |value|
    if result
      result << ", #{value}"
    else
      result = "#{value}"
    end
  end

  puts result
end
