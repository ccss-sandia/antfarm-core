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

# EthernetInterface class that wraps the ethernet_interfaces
# table in the ANTFARM database.
#
# * belongs to a layer 2 interface
#
# The node_name and node_device_type attributes are only applicable
# when an existing node is not specified.
#
# The node and layer2_interface_media_type attributes are only
# applicable when an existing layer 2 interface is not specified.
module Antfarm
  module Models
    class EthernetInterface
      include DataMapper::Resource

      storage_names[:default] = 'ethernet_interfaces'

      property :id,      Serial
      property :address, String, :null => false
      property :custom,  String

      belongs_to :layer2_interface, :key => "id"

      before :create, :create_layer2_interface

      # Media type of the layer 2 interface automatically
      # creted for this ethernet interface.
      attr_writer :layer2_interface_media_type

      # Existing node the layer 2 interface automatically
      # created for this ethernet interface should belong to.
      attr_writer :node

      # Name of the node automatically created by the layer 2
      # interface created for this ethernet interface.
      attr_writer :node_name

      # Device type of the node automatically created by the
      # layer 2 interface created for this ethernet interface.
      attr_writer :node_device_type

      # This ensures that the MAC address entered is of the right format.  It is called
      # *before* the before_create method below is called, which keeps the Layer2Interface
      # from being created if the address format is not valid.
      validates_format :address, :with => /^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$/i,
                                 :on => :save,
                                 :message => "invalid MAC address format"

      validates_present :address

      #######
      private
      #######

      def create_layer2_interface
        unless self.layer2_interface
          layer2_interface = Layer2Interface.new :certainty_factor => 0.75
          layer2_interface.media_type = @layer2_interface_media_type if @layer2_interface_media_type
          layer2_interface.node = @node if @node
          layer2_interface.node_name = @node_name if @node_name
          layer2_interface.node_device_type = @node_device_type if @node_device_type
          if layer2_interface.save
            Antfarm::Helpers.log :info, "EthernetInterface: Create Layer 2 Interface"
          else
            Antfarm::Helpers.log :warn, "EthernetInterface: Errors occured while creating Layer 2 Interface"
            layer2_interface.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end

          self.layer2_interface = layer2_interface
        end
      end
    end
  end
end
