# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

require 'ipaddrext'
require 'layer3_network'

class IpNetwork < ActiveRecord::Base
  belongs_to :layer3_network, :foreign_key => "id"
  belongs_to :private_network

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

  # Any variables native to this object that are being validated against must
  # be present before the before_create method is called. This is why I have
  # moved the private address check here. If I decide to validate associations
  # in the future, then the creation of associated objects will probably have
  # to be moved here as well.
# def before_validation_on_create
#   if @ip_net.private_address?
#     self.private = true
#     # TODO: Create private network objects.
#   end
# end

  # Things to do before saving a newly created network to the database.
  def before_create
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

      self.private = true if @ip_net.private_address?
    end
  end

  # Things to do after a newly created network has been saved to the database.
  def after_create
    # Merge any existing networks already in the database that are
    # sub_networks of this new network.
    Layer3Network.merge(self.layer3_network, 0.80)
  end

  # This is for ActiveScaffold
  def to_label
    return address
  end
end
