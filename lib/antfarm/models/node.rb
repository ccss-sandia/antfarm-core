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

# Node class that wraps the nodes table in the ANTFARM database.
#
# * has many layer 2 interfaces
# * has many layer 3 interfaces through layer 2 interfaces
module Antfarm
  module Models
    class Node
      include DataMapper::Resource

      storage_names[:default] = 'nodes'

      property :id,               Serial
      property :certainty_factor, Float, :null => false
      property :name,             String
      property :device_type,      String
      property :custom,           String

      has n, :layer2_interfaces
      has n, :layer3_interfaces, :through => :layer2_interfaces
      has n, :services
      has 1, :operating_systems

      has_tags_on :tags

      before :save, :clamp_certainty_factor

      validates_present :certainty_factor

      # Find and return the first node found with the given name.
      def self.node_named(name)
        unless name
          raise(ArgumentError, "nil argument supplied", caller)
        end

        node = self.find_all_by_name(name)

        case node.length
        when 0
          Antfarm::Helpers.log :warn, "Node: did not find an existing node with given name."
          return nil
        else
          Antfarm::Helpers.log :info, "Node: found existing nodes with given name."
          return node[0]
        end
      end

      # Find and return all the nodes found that are the given type.
      def self.nodes_of_device_type(device_type)
        unless device_type
          raise(ArgumentError, "nil argument supplied", caller)
        end

        nodes = self.find_all_by_device_type(device_type)

        case nodes.length
        when 0
          Antfarm::Helpers.log :warn, "Node: did not find any existing nodes of given device type."
          return nil
        else
          Antfarm::Helpers.log :info, "Node: found existing nodes of given device type."
          return nodes
        end
      end

      #######
      private
      #######

      def clamp_certainty_factor
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
