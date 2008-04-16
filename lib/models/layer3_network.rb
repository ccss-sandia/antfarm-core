# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>
#
# TODO: IPAddr is giving me fits.  If you have two networks, say 10.0.0.0/16 and 10.0.0.0/24,
#       executing IPAddr.include? will return true when each is compared to the other.  I was
#       expecting to have true returned when I asked if /16 included /24, and false returned
#       when I asked if /24 included /16.  However, I got true returned in both cases...
#
# Added network_in_network? method to IPAddrExt.  This should fix the problem discussed above.

require 'antfarm'
require 'ipaddrext'
require 'ip_network'

class Layer3Network < ActiveRecord::Base
  has_many :layer3_interfaces
  has_one  :ip_network, :foreign_key => "id", :dependent => :destroy

  before_save :clamp_certainty_factor

  validates_presence_of :certainty_factor

  # This method takes the given network and merges with it any sub_networks of the given
  # network.
  # TODO: change 1.0 to CF_PROVEN_TRUE once Antfarm module is created and included in
  # this file.
  def self.merge(network, merge_certainty_factor = 1.0)
    unless network 
      raise(ArgumentError, "nil argument supplied", caller)
    end

    for sub_network in self.networks_contained_within(network.ip_network.address)
      unless sub_network == network 
        unless merge_certainty_factor
          # TODO: change 0.0 to CF_LACK_OF_PROOF once Antfarm module is created and
          # included in this file.
          merge_certainty_factor = 0.0
        end

        # TODO: uncomment the line below once Antfarm module is created and included
        # in this file.
#         merge_certainty_factor = clamp(merge_certainty_factor, CF_PROVEN_FALSE, CF_PROVEN_TRUE)

        l3_ifs = network.layer3_interfaces
        l3_ifs << sub_network.layer3_interfaces
        l3_ifs.flatten!

        network.update_attributes({:layer3_interfaces => l3_ifs})

        # TODO: update network's certainty factor using sub_network's certainty factor.
        
        # Because of :dependent => :destroy above, calling destroy here will also cause
        # destroy to be called on ip_network
        sub_network.destroy
      end
    end
  end

  # Find the Layer3Network with the given address.
  def self.network_addressed(ip_net_str)
    # Calling network_containing here because if a network already exists that encompasses
    # the given network, we want to automatically use that network instead.
    #
    # TODO: figure out how to use alias with class methods
    self.network_containing(ip_net_str)
  end

  # Find the network the given network is a sub_network of, if one exists.
  #
  # Don't want to require a Layer3Network to be passed in case a check is being performed
  # before a Layer3Network is created.
  def self.network_containing(ip_net_str)
    unless ip_net_str
      raise(ArgumentError, "nil argument supplied", caller)
    end

    ip_nets = IpNetwork.find(:all)
    for ip_net in ip_nets
      if Antfarm::IPAddrExt.new(ip_net.address).network_in_network?(Antfarm::IPAddrExt.new(ip_net_str))
        return Layer3Network.find(ip_net.id)
      end
    end

    return nil
  end

  # Find any Layer3Networks that are sub_networks of the given network.
  #
  # Don't want to require a Layer3Network to be passed in case a check is being performed
  # before a Layer3Network is created.
  def self.networks_contained_within(ip_net_str)
    unless ip_net_str
      raise(ArgumentError, "nil argument supplied", caller)
    end

    network = Antfarm::IPAddrExt.new(ip_net_str)
    sub_networks = Array.new

    ip_nets = IpNetwork.find(:all)
    for ip_net in ip_nets
      sub_networks << Layer3Network.find(ip_net.id) if network.network_in_network?(ip_net.address)
    end

    return sub_networks
  end

  # This is for ActiveScaffold
  def to_label
    return "#{id} -- #{ip_network.address}" if ip_network
    return "#{id} -- Generic Layer3 Network"
  end

  #######
  private
  #######

  def clamp_certainty_factor
    self.certainty_factor = Antfarm.clamp(self.certainty_factor)
  end
end

