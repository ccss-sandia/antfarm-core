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

# Layer3Interface class that wraps the layer3_interfaces table
# in the ANTFARM database.
#
# * has many traffic entries (defined as outbound_traffic)
# * has many traffic entries (defined as inbound_traffic)
# * has one IP interface
# * belongs to a layer 3 network
# * belongs to a layer 2 interface
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
  module Models
    class Layer3Interface
      include DataMapper::Resource

      storage_names[:default] = 'layer3_interfaces'

      property :id,                  Serial
      property :layer2_interface_id, Integer, :null => false
      property :layer3_network_id,   Integer, :null => false
      property :certainty_factor,    Float,   :null => false
      property :protocol,            String
      property :custom,              String

      has n,     :outbound_traffic, :class_name => "Traffic", :child_key => [:source_id]
      has n,     :inbound_traffic,  :class_name => "Traffic", :child_key => [:target_id]
      has n,     :ip_interfaces,    :one_to_one => true, :key => "id"
      belongs_to :layer2_interface
      belongs_to :layer3_network

      before :create, :create_layer3_network
      before :create, :create_layer2_interface
      before :save,   :clamp_certainty_factor

      # Protocol of the layer 3 network automatically
      # created for this layer 3 interface.
      attr_writer :layer3_network_protocol

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

      validates_present :certainty_factor

      # Find and return the layer 3 interface
      # with the given IP address.
      def self.interface_addressed(ip_addr_str)
        unless ip_addr_str
          raise(ArgumentError, "nil argument supplied", caller)
        end

        ip_ifs = IpInterface.find(:all)
        for ip_if in ip_ifs
          if Antfarm::IPAddrExt.new(ip_addr_str) == Antfarm::IPAddrExt.new(ip_if.address)
            return Layer3Interface.find(ip_if.id)
          end
        end

        return nil
      end

      #######
      private
      #######

      def create_layer3_network
        unless self.layer3_network
          layer3_network = Layer3Network.new :certainty_factor => 0.75
          layer3_network.protocol = @layer3_network_protocol if @layer3_network_protocol
          if layer3_network.save
            Antfarm::Helpers.log :info, "Layer3Interface: Created Layer 3 Network"
          else
            Antfarm::Helpers.log :warn, "Layer3Interface: Errors occured while creating Layer 3 Network"
            layer3_network.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end

          self.layer3_network = layer3_network
        end
      end

      def create_layer2_interface
        unless self.layer2_interface
          layer2_interface = Layer2Interface.new :certainty_factor => 0.75
          layer2_interface.media_type = @layer2_interface_media_type if @layer2_interface_media_type
          layer2_interface.node = @node if @node
          layer2_interface.node_name = @node_name if @node_name
          layer2_interface.node_device_type = @node_device_type if @node_device_type
          if layer2_interface.save
            Antfarm::Helpers.log :info, "Layer3Interface: Created Layer 2 Interface"
          else
            Antfarm::Helpers.log :warn, "Layer3Interface: Errors occured while creating Layer 2 Interface"
            layer2_interface.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end

          self.layer2_interface = layer2_interface
        end
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
