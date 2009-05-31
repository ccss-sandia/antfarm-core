module Antfarm
  module Models
    class Layer3Network
      include DataMapper::Resource

      property :id, Serial

      has 1, :ip_network, :child_key => [:id]
      has n, :layer3_interfaces

      before :save, :clamp_certainty_factor
      before :destroy do
        ip_network.destroy
      end
      after :create do
        Antfarm::Helpers.log :debug, "Just created Layer3Network #{self.id}"
      end
      after :destroy do
        puts "Just destroyed Layer3Network #{self.ip_network.address}"
      end

      # Take the given network and merge with it
      # any sub_networks of the given network.
      def self.merge(network, merge_certainty_factor = Antfarm::CF_PROVEN_TRUE)
        Antfarm::Helpers.log :debug, 'Layer3Network#merge called'

        Antfarm::Helpers.log :debug, "Inside Layer3Network#merge - #{network.ip_network.address}"

        unless network
          raise(ArgumentError, "nil argument supplied", caller)
        end

        for sub_network in self.networks_contained_within(network.ip_network.address)
#         Antfarm::Helpers.log :debug, "Inside Layer3Network#merge-for_loop - #{sub_network.ip_network.address}"
          unless sub_network == network
#           Antfarm::Helpers.log :debug, 'Inside Layer3Network#merge-for_loop-unless_block'
            unless merge_certainty_factor
              merge_certainty_factor = Antfarm::CF_LACK_OF_PROOF
            end

            merge_certainty_factor = Antfarm::Helpers.clamp(merge_certainty_factor)

            sub_network.layer3_interfaces.each { |interface| network.layer3_interfaces << interface }
            network.layer3_interfaces.uniq!

            # TODO: update network's certainty factor using sub_network's certainty factor.

            network.save

            # Because of the destroy block above, calling destroy
            # here will also cause destroy to be called on ip_network
            sub_network.destroy
          end
        end
      end

      def self.network_containing(ip_net_str)
        unless ip_net_str
          raise(ArgumentError, "nil argument supplied", caller)
        end

        # Don't want to require a Layer3Network to be passed in case a check is being performed
        # before a Layer3Network is created.
        network = Antfarm::IPAddrExt.new(ip_net_str)

        ip_nets = IpNetwork.all
        for ip_net in ip_nets
          if Antfarm::IPAddrExt.new(ip_net.address).network_in_network?(network)
            return ip_net.layer3_network
          end
        end

        return nil
      end

      def self.networks_contained_within(ip_net_str)
        unless ip_net_str
          raise(ArgumentError, "nil argument supplied", caller)
        end

        # Don't want to require a Layer3Network to be passed in case
        # a check is being performed before a Layer3Network is created.
        network = Antfarm::IPAddrExt.new(ip_net_str)
        sub_networks = Array.new

        ip_nets = IpNetwork.all
        for ip_net in ip_nets
#         Antfarm::Helpers.log :debug, "Inside Layer3Network#networks_contained_within - #{ip_net.address}"
          sub_networks << ip_net.layer3_network if network.network_in_network?(ip_net.address)
        end

        return sub_networks
      end

      private

      def clamp_certainty_factor
        puts 'Layer3Network#clamp_certainty_factor called'
      end
    end
  end
end
