# Copyright 2004 Sandia National Laboratories
# Original Author: Michael Berg <mjberg@sandia.gov>
# Modified By: Bryan T. Richardson <btricha@sandia.gov>

require 'ipaddr'

module Antfarm

  # Symbolic marker points on the fuzzy logic certainty factor scale.
  # Certainty Factors (CF)
  CF_PROVEN_TRUE   =  1.0000
  CF_LIKELY_TRUE   =  0.5000
  CF_LACK_OF_PROOF =  0.0000
  CF_LIKELY_FALSE  = -0.5000
  CF_PROVEN_FALSE  = -1.0000

  # Amount by which a value can differ and still be considered the same.
  # Mainly used as a buffer against floating point round-off errors.
  CF_VARIANCE      =  0.0001

  def self.clamp(x, low = CF_PROVEN_FALSE, high = CF_PROVEN_TRUE)
    if x < low
      return low
    elsif x > high
      return high
    else
      return x
    end
  end

  def self.simplify_interfaces
    #TODO
  end

  def self.timestamp
    return Time.now.utc.xmlschema
  end

  def self.db_file_to_use
    if defined? USER_DIR
      return File.expand_path("#{USER_DIR}/db/#{ANTFARM_ENV}.db")
    else
      return File.expand_path("#{ANTFARM_ROOT}/db/#{ANTFARM_ENV}.db")
    end
  end

  def self.db_dir_to_use
    if defined? USER_DIR
      return File.expand_path("#{USER_DIR}/db")
    else
      return File.expand_path("#{ANTFARM_ROOT}/db")
    end
  end

  def self.log_file_to_use
    if defined? USER_DIR
      return File.expand_path("#{USER_DIR}/log/#{ANTFARM_ENV}.log")
    else
      return File.expand_path("#{ANTFARM_ROOT}/log/#{ANTFARM_ENV}.log")
    end
  end

  def self.log_dir_to_use
    if defined? USER_DIR
      return File.expand_path("#{USER_DIR}/log")
    else
      return File.expand_path("#{ANTFARM_ROOT}/log")
    end
  end

  # Some explanation to having @netmask and such:
  #   If you create a new IPAddr object and you include
  #   the network information for the IP address, IPAddr
  #   doesn't keep track of the actual address, and
  #   instead just keeps track of the network.  For
  #   example, if you were to create a new IPAddr object
  #   using the following code:
  #
  #   IPAddr.new("192.168.101.5/24")
  #
  #   the resulting object would be of the form:
  #
  #   <IPAddr: IPv4:192.168.101.0/255.255.255.0>
  #
  #   and there would be no way to retrieve the original
  #   address (192.168.101.5).  By creating this class,
  #   Michael has made it possible to keep track of both
  #   the address and the network information.  This is
  #   useful in the case of creating a new IPInterface
  #   object.
  #
  # TODO: If a netmask is given, should we somehow check
  #       to see if an address is being given with network
  #       information or if a network is being specified,
  #       and if it is a network, should we validate that
  #       the network address is valid with the given
  #       netmask?  This may be done automatically... I
  #       need to look more into how IPAddr works.

  class IPAddrExt < IPAddr
    def initialize(value)
      address,netmask = value.split('/')
      super(address)

      if self.ipv4?
        @netmask = IPAddr.new('255.255.255.255')
        @addr_bits = 32
      elsif self.ipv6?
        @netmask = IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff')
        @addr_bits = 128
      else
        #TODO: Error
      end
   
      if netmask
        @netmask = @netmask.mask(netmask)
      end
    end

    attr_accessor :netmask

    def netmask_length
      mask_len = @addr_bits
      unless (~@netmask).to_i == 0
        res = Math.log((~@netmask).to_i) / Math.log(2)
        if res.finite?
          mask_len -= res.round
        end
      end

      return mask_len
    end

    def network
      return self.mask(self.netmask.to_s)
    end

    def to_cidr_string
      str = sprintf("%s/%s", self.network.to_string, self.netmask_length.to_s)
      return str
    end

    def broadcast
      return self.network | ~self.netmask
    end
   
    # TODO: track down the IPv6 private use ranges and include them
    def private_address?
      private_addr_list = [
        '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16',
        'fe80::/10', 'fec0::/10'
      ]
      return self.in_address_list?(private_addr_list)
    end

    #TODO: track down IPv6 localnet mask (guessing /10 for now)
    def loopback_address?
      loopback_addr_list = ['127.0.0.0/8', '::1', 'fe00::/10']
      return self.in_address_list?(loopback_addr_list)
    end

    # Need to verify the IPv4 multicast addrs (couldn't find the whole
    # block, only the currently assigned ranges within the block)
    def multicast_address?
      multicast_addr_list = ['224.0.0.0/4', 'ff00::/8']
      return self.in_address_list?(multicast_addr_list)
    end

    def in_address_list?(addr_str_list)
      for addr_str in addr_str_list
        addr = IPAddr.new(addr_str)
        if addr.include?(self)
          return true
        end
      end

      return false    
    end

    # Decides if the given network is a subset of this network.
    # This method was added since SQLite3 cannot handle CIDR's
    # 'natively' like PostgreSQL can. Note that this method
    # also works if the network given is actually a host.
    def network_in_network?(network)
      broadcast = nil

      if network.kind_of?(String)
        broadcast = IPAddrExt.new(network).broadcast
        network = IPAddr.new(network)
      elsif network.kind_of?(Antfarm::IPAddrExt)
        broadcast = network.broadcast
        network = IPAddr.new(network.to_cidr_string)
      else
        raise(ArgumentError, "argument should be either a String or an Antfarm::IPAddrExt object", caller)
      end

      return false unless IPAddr.new(self.to_cidr_string).include?(network)
      return false unless IPAddr.new(self.to_cidr_string).include?(broadcast)
      return true
    end
  end

end

