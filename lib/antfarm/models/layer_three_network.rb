################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

module Antfarm
  module Model
    class LayerThreeNetwork
      include DataMapper::Resource

      storage_names[:default] = 'layer_three_networks'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :protocol,         String
      property :custom,           String

      has n, :layer_three_interfaces, :constraint => :destroy
      has 1, :ip_network,             :constraint => :destroy

      validates_present :certainty_factor

      before :save, :clamp_certainty_factor

      # Take the given network and merge with it
      # any sub_networks of the given network.
      def self.merge(network, merge_certainty_factor = Antfarm::CF_PROVEN_TRUE)
        unless network 
          raise(ArgumentError, 'nil argument supplied to LayerThreeNetwork#merge', caller)
        end

        unless network.is_a?(Antfarm::Model::LayerThreeNetwork)
          raise(ArgumentError, 'argument supplied to LayerThreeNetwork#merge must be LayerThreeNetwork', caller)
        end

        for sub_network in self.networks_contained_within(network.ip_network.address)
          unless sub_network == network 
            unless merge_certainty_factor
              merge_certainty_factor = Antfarm::CF_LACK_OF_PROOF
            end

            merge_certainty_factor = Antfarm::Helpers.clamp(merge_certainty_factor)

            sub_network.layer_three_interfaces.each { |interface| network.layer_three_interfaces << interface }
            network.layer_three_interfaces.uniq!

            # Clear out the layer 3 interfaces on the network to
            # be destroyed such that they aren't destroyed too.
            sub_network.layer_three_interfaces.clear

            # TODO: update network's certainty factor using sub_network's certainty factor.
            
            network.save

            # Because of :constraint => :destroy above, calling destroy
            # here will also cause destroy to be called on ip_network.
            # Calling destroy here should NOT destroy any layer 3 interface
            # since they were all moved over to the network being merged to.
            sub_network.destroy
          end
        end
      end

      # Find the Layer3Network with the given address.
      def self.network_addressed(ip_net_str)
        unless ip_net_str
          raise(ArgumentError, 'nil argument supplied to LayerThreeNetwork#network_addressed', caller)
        end

        # Calling network_containing here because if a network already exists that encompasses
        # the given network, we want to automatically use that network instead.
        # TODO: figure out how to use alias with class methods
        self.network_containing(ip_net_str)
      end

      # Find the network the given network is a sub_network of, if one exists.
      def self.network_containing(ip_net_str)
        unless ip_net_str
          raise(ArgumentError, 'nil argument supplied to LayerThreeNetwork#network_containing', caller)
        end

        # Don't want to require a Layer3Network to be passed in case
        # a check is being performed before a Layer3Network is created.
        network = Antfarm::IPAddrExt.new(ip_net_str)

        ip_nets = IpNetwork.all
        for ip_net in ip_nets
          if Antfarm::IPAddrExt.new(ip_net.address).network_in_network?(network)
            return ip_net.layer_three_network
          end
        end

        return nil
      end

      # Find any Layer3Networks that are sub_networks of the given network.
      def self.networks_contained_within(ip_net_str)
        unless ip_net_str
          raise(ArgumentError, 'nil argument supplied to LayerThreeNetwork#networks_contained_within', caller)
        end

        # Don't want to require a Layer3Network to be passed in case
        # a check is being performed before a Layer3Network is created.
        network = Antfarm::IPAddrExt.new(ip_net_str)
        sub_networks = Array.new

        ip_nets = IpNetwork.all
        for ip_net in ip_nets
          sub_networks << ip_net.layer_three_network if network.network_in_network?(ip_net.address)
        end

        return sub_networks
      end

      #######
      private
      #######

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerThreeNetwork#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
