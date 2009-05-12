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

# Layer2Interface class that wraps the layer2_interfaces table
# in the ANTFARM database.
#
# * has many layer 3 interfaces
# * has one ethernet interface
# * belongs to a node
#
# The node_name and node_device_type attributes are only applicable
# when an existing node is not specified.
module Antfarm
  module Models
    class Layer2Interface
      include DataMapper::Resource

      storage_names[:default] = 'layer2_interfaces'

      property :id,               Serial
      property :node_id,          Integer, :null => false
      property :certainty_factor, Float,   :null => false
      property :media_type,       String
      property :custom,           String

      has n,     :layer3_interfaces
      has 1,     :ethernet_interfaces, :child_key => [:id]
      belongs_to :node

      has_tags_on :tags

      before :create, :create_node
      before :save,   :clamp_certainty_factor

      # Name of the node automatically created for this
      # layer 2 interface.
      attr_writer :node_name

      # Device type of the node automatically created for
      # this layer 2 interface.
      attr_writer :node_device_type

      validates_present :certainty_factor

      # Find and return the layer 2 interface with the
      # given ethernet address.
      def self.interface_addressed(mac_addr_str)
        unless mac_addr_str
          raise(ArgumentError, "nil argument supplied", caller)
        end

        eth_ifs = EthernetInterface.find(:all)
        for eth_if in eth_ifs
          if mac_addr_str == eth_if.address
            return Layer2Interface.find(eth_if.id)
          end
        end

        return nil
      end

      #######
      private
      #######

      def create_node
        unless self.node
          if @node_name
            nodes = Node.find_all_by_name(@node_name)
            case nodes.length
            when 0
              node = Node.new :certainty_factor => 0.75
              node.name = @node_name
            when 1
              node = nodes.first
            else
              #TODO: do something here with certainty factor?
              node = nodes.first
            end
          else
            node = Node.new :certainty_factor => 0.75
          end
          #TODO: do something here with certainty factor?
          node.device_type = @node_device_type if @node_device_type
          if node.save
            Antfarm::Helpers.log :info, "Layer2Interface: Created Node"
          else
            Antfarm::Helpers.log :warn, "Layer2Interface: Errors occured while creating Node"
            node.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end

          self.node = node
        end
      end

      def clamp_certainty_factor
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
