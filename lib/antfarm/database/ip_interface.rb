# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 

# IpInterface class that wraps the ip_interfaces table
# in the ANTFARM database.
#
# * belongs to a layer 3 interface
#
# The node_name and node_device_type attributes are only applicable
# when an existing node is not specified.
#
# The node and layer2_interface_media_type attributes are only
# applicable when an existing layer 2 interface is not specified.
#
# The layer3_network_protocol attribute is only applicable when
# an existing layer 3 network is not specified.
module Antfarm
  module Database
    class IpInterface
      include DataMapper::Resource

      property :id,      Serial
      property :address, String,  :null => false
      property :virtual, Boolean, :null => false, :default => false
      property :custom,  String

      belongs_to :layer3_interface, :key => "id"

      before :create, :create_layer3_interface

      # Existing layer 3 network the layer 3 interface
      # automatically created for this IP interface
      # should belong to.
      attr_writer :layer3_network

      # Protocol of the layer 3 network automatically
      # created for the layer 3 interface created for
      # this IP interface.
      attr_writer :layer3_network_protocol

      # Protocol of the layer 3 interface automatically
      # created for this IP interface.
      attr_writer :layer3_interface_protocol

      # Ethernet (MAC) address of the ethernet interface
      # to be created for this IP interface.
      attr_writer :ethernet_address

      # Existing layer 2 interface the layer 3 interface
      # automatically created for this IP interface
      # should belong to.
      attr_writer :layer2_interface

      # Media type of the layer 2 interface automatically
      # creted for this layer 3 interface.
      attr_writer :layer2_interface_media_type

      # Existing node the layer 2 interface automatically
      # created for this layer 3 interface should belong to.
      attr_writer :node

      # Name of the node automatically created by the layer 2
      # interface created for this layer 3 interface.
      attr_writer :node_name

      # Device type of the node automatically created by the
      # layer 2 interface created for this layer 3 interface.
      attr_writer :node_device_type

      # Overriding the address setter in order to create an instance variable for an
      # Antfarm::IPAddrExt object ip_addr.  This way the rest of the methods in this
      # class can confidently access the ip address for this interface.  IPAddr also
      # validates the address.
      #
      # the method address= is called by the constructor of this class.
      def address=(ip_addr) #:nodoc:
        @ip_addr = Antfarm::IPAddrExt.new(ip_addr)
        super(@ip_addr.to_s)
      end

      validates_presence_of :address

      # Validate data for requirements before saving interface to the database.
      #
      # Was using validate_on_create, but decided that restraints should occur
      # on anything saved to the database at any time, including a create and an update.
      def validate #:nodoc:
        # Don't save the interface if it's a loopback address.
        if @ip_addr.loopback_address?
          errors.add(:address, "loopback address not allowed")
        end

        # If the address is public and it already exists in the database, don't create
        # a new one but still create a new IP Network just in case the data given for
        # this address includes more detailed information about its network.
        unless @ip_addr.private_address?
          interface = IpInterface.find_by_address(address)
          if interface
            create_ip_network
            errors.add(:address, "#{address} already exists, but a new IP Network was created")
          end
        end
      end

      #######
      private
      #######

      def create_layer3_interface
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
            layer3_interface.layer3_network = create_ip_network
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
            layer3_interface.node_device_type = @node_device_type if @node_device_type
          end

          if layer3_interface.save
            Antfarm::Helpers.log :info, "IpInterface: Created Layer 3 Interface"
          else
            Antfarm::Helpers.log :warn, "IpInterface: Errors occured while creating Layer 3 Interface"
            layer3_interface.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end

          self.layer3_interface = layer3_interface
        end
      end

      def create_ip_network
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
            Antfarm::Helpers.log :info, "IpInterface: Created IP Network"
          else
            Antfarm::Helpers.log :warn, "IpInterface: Errors occured while creating IP Network"
            ip_network.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end
          layer3_network = ip_network.layer3_network
        end
        return layer3_network
      end
    end
  end
end
