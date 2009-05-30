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

# IpNetwork class that wraps the ip_networks table
# in the ANTFARM database.
#
# * belongs to a layer 3 network
# * belongs to a private network
module Antfarm
  module Models
    class IpNetwork
      include DataMapper::Resource

      storage_names[:default] = 'ip_networks'

      property :id,                 Serial
      property :private_network_id, Integer
      property :address,            String,  :null => false
      property :private,            Boolean, :null => false, :default => false
      property :custom,             String

      belongs_to :layer3_network, :child_key => [:id]
      belongs_to :private_network

      has_tags_on :tags

      before :create, :create_layer3_network
      before :create, :set_private_address
      after  :create, :merge_layer3_networks

      # Protocol of the layer 3 network automatically
      # created for this IP network.
      attr_writer :layer3_network_protocol

      # Description of the private network to be
      # created for this IP network if it's private.
      attr_writer :private_network_description

      # Validate data for requirements before saving network to the database.

      validates_present :address

      # Don't save the network if it's a loopback network.
      validates_with_block :address do
        if @ip_net.loopback_address?
          [ false, 'loopback address not allowed' ]
        else
          true
        end
      end

      # Overriding the address setter in order to create an instance variable for an
      # Antfarm::IPAddrExt object ip_net.  This way the rest of the methods in this
      # class can confidently access the ip address for this network.
      #
      # the method address= is called by the constructor of this class.
      def address=(ip_addr) #:nodoc:
        @ip_net = Antfarm::IPAddrExt.new(ip_addr)
        attribute_set :address, @ip_net.to_cidr_string
      end

      #######
      private
      #######

      def set_private_address
        Antfarm::Helpers.log :info, "IpNetwork: Setting Private Address"
        self.private = @ip_net.private_address?
        # TODO: Create private network objects.
        return # if we don't do this, then a false is returned and the save fails
      end

      def create_layer3_network
        # If we get to this point, then we know a network does not
        # already exist because validate gets called before
        # this method and we're checking for existing networks in
        # validate.  Therefore, we know a new network needs to be created,
        # unless it was specified by the user.
        unless self.layer3_network
          self.layer3_network = Layer3Network.new :certainty_factor => 0.75
          self.layer3_network.protocol = @layer3_network_protocol if @layer3_network_protocol
          if self.layer3_network.save
            Antfarm::Helpers.log :info, "IpNetwork: Created Layer 3 Network"
          else
            Antfarm::Helpers.log :warn, "IpNetwork: Errors occured while creating Layer 3 Network"
            self.layer3_network.errors.each_full do |msg|
              Antfarm::Helpers.log :warn, msg
            end
          end
        end
      end

      def merge_layer3_networks
        # Merge any existing networks already in the database that are
        # sub_networks of this new network.
        Layer3Network.merge(self.layer3_network, 0.80)
      end
    end
  end
end
