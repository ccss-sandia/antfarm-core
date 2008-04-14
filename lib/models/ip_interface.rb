# Copyright 2008 Sandia National Laboratories
# Original Author: Bryan T. Richardson <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>

require 'ethernet_interface'
require 'ipaddrext'
require 'ip_network'
require 'layer3_interface'
require 'layer3_network'

class IpInterface < ActiveRecord::Base
  belongs_to :layer3_interface, :foreign_key => "id"

  # Added to make it possible to specify what to set for the Layer3Network and/or
  # the Layer2Interface, as well as what to set for either the node object or the
  # node type for the Layer2Interface that will be associated with this interface.
  attr_writer :layer3_network, :layer3_network_protocol,
              :layer3_interface_protocol,
              :ethernet_address,
              :layer2_interface, :layer2_interface_media_type,
              :node, :node_name, :node_type

  # Overriding the address setter in order to create an instance variable for an
  # Antfarm::IPAddrExt object ip_addr.  This way the rest of the methods in this
  # class can confidently access the ip address for this interface.  IPAddr also
  # validates the address.
  #
  # the method address= is called by the constructor of this class.
  def address=(ip_addr)
    @ip_addr = Antfarm::IPAddrExt.new(ip_addr)
    super(@ip_addr.to_s)
  end

#   validates_format_of :address, :with => /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/i,
#                                 :on => :save,
#                                 :message => "invalid IP address format"

  validates_presence_of :address

  # Validate data for requirements before saving interface to the database.
  #
  # Was using validate_on_create, but decided that restraints should occur
  # on anything saved to the database at any time, including a create and an update.
  def validate
    # Don't save the interface if it's a loopback address.
    unless !@ip_addr.loopback_address?
      errors.add(:address, "loopback address not allowed")
    end
  end

  # Things to do before saving a newly created interface to the database.
  def before_create
    # If we get to this point, then we know an interface does not
    # already exist because validate gets called before
    # this method and we're checking for existing interfaces in
    # validate.  Therefore, we know a new interface needs to be created,
    # unless it was specified by the user.
    
    unless self.layer3_interface
      layer3_interface = Layer3Interface.new :certainty_factor => 0.75
      layer3_interface.protocol = @layer3_interface_protocol if @layer3_interface_protocol

      if @layer3_network
        layer3_interface.layer3_network = @layer3_network
      else
        # Check to see if a network exists that contains this address.
        # If not, create a small one that does.
        layer3_network = Layer3Network.network_containing(@ip_addr.to_cidr_string)
        unless layer3_network
          network = @ip_addr.clone
          if network == network.network
            network.netmask = network.netmask << 3
          end

          ip_network = IpNetwork.new :address => network.to_cidr_string
          ip_network.layer3_network_protocol = @layer3_network_protocol if @layer3_network_protocol
          if ip_network.save
            logger.info("IpInterface: Created IP Network")
#           puts "IPInterface: Created IP Network"
          else
            logger.warn("IpInterface: Errors occured while creating IP Network")
#           puts "IPInterface: Errors occured while creating IP Network"
            ip_network.errors.each_full do |msg|
              logger.warn(msg)
#             puts msg
            end
          end

          layer3_network = ip_network.layer3_network
        end

        layer3_interface.layer3_network = layer3_network
      end

      if @layer2_interface
        layer3_interface.layer2_interface = @layer2_interface
      else
        if @ethernet_address
          ethernet_interface = EthernetInterface.create :address => @ethernet_address
          layer3_interface.layer2_interface = ethernet_interface.layer2_interface
        end

        layer3_interface.layer2_interface_media_type = @layer2_interface_media_type if @layer2_interface_media_type
        layer3_interface.node = @node if @node
        layer3_interface.node_name = @node_name if @node_name
        layer3_interface.node_type = @node_type if @node_type
      end

      if layer3_interface.save
        logger.info("IpInterface: Created Layer 3 Interface")
#       puts "IPInterface: Created Layer 3 Interface"
      else
        logger.warn("IpInterface: Errors occured while creating Layer 3 Interface")
#       puts "IPInterface: Errors occured while creating Layer 3 Interface"
        layer3_interface.errors.each_full do |msg|
          logger.warn(msg)
#         puts msg
        end
      end

      self.layer3_interface = layer3_interface
    end
  end

  # This is for ActiveScaffold
  def to_label
    return address
  end
end
