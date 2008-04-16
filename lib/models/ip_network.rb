# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

require 'ipaddrext'
require 'layer3_network'

class IpNetwork < ActiveRecord::Base
  belongs_to :layer3_network, :foreign_key => "id"
  belongs_to :private_network

  before_validation :set_private_address
  before_create :create_layer3_network
  after_create :merge_layer3_networks

  # Added to make it possible to specify what to set for the protocol for the
  # Layer3Network that will be associated with this network.
  attr_writer :layer3_network_protocol, :private_network_description

  validates_presence_of :address

  # Overriding the address setter in order to create an instance variable for an
  # Antfarm::IPAddrExt object ip_net.  This way the rest of the methods in this
  # class can confidently access the ip address for this network.
  #
  # the method address= is called by the constructor of this class.
  def address=(ip_addr)
    @ip_net = Antfarm::IPAddrExt.new(ip_addr)
    super(@ip_net.to_cidr_string)
  end

  # Validate data for requirements before saving network to the database.
  #
  # Was using validate_on_create, but decided that these restraints should occur
  # on anything saved to the database at any time, including a create and an update.
  def validate
    # Don't save the network if it's a loopback network.
    unless !@ip_net.loopback_address?
      errors.add(:address, "loopback address not allowed")
    end
  end

  # This is for ActiveScaffold
  def to_label
    return address
  end

  #######
  private
  #######

  def set_private_address
    self.private = @ip_net.private_address?
    # TODO: Create private network objects.
    return true
  end

  def create_layer3_network
    # If we get to this point, then we know a network does not
    # already exist because validate gets called before
    # this method and we're checking for existing networks in
    # validate.  Therefore, we know a new network needs to be created,
    # unless it was specified by the user.

    unless self.layer3_network
      layer3_network = Layer3Network.new :certainty_factor => 0.75
      layer3_network.protocol = @layer3_network_protocol if @layer3_network_protocol
      if layer3_network.save
        logger.info("IpNetwork: Created Layer 3 Network")
#       puts "IPNetwork: Created Layer 3 Network"
      else
        logger.warn("IpNetwork: Errors occured while creating Layer 3 Network")
#       puts "IPNetwork: Errors occured while creating Layer 3 Network"
        layer3_network.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end

      self.layer3_network = layer3_network
    end
  end

  def merge_layer3_networks
    # Merge any existing networks already in the database that are
    # sub_networks of this new network.
    Layer3Network.merge(self.layer3_network, 0.80)
  end
end

