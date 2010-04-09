module Antfarm
  module Models
    class IpNetwork
      include DataMapper::Resource

      property :id,      Serial
      property :address, String, :nullable => false

      belongs_to :layer3_network, :child_key => [:id]

      validates_present :address

      has_tags_on :tags

      before :create, :create_layer3_network
      before :create, :set_private_address
      after  :create, :merge_layer3_networks
      after :create do
        Antfarm::Helpers.log :debug, "Just created IpNetwork #{self.id}"
      end

      private

      def create_layer3_network
        Antfarm::Helpers.log :debug, 'IpNetwork#create_layer3_network called'
        self.layer3_network = Layer3Network.create
      end

      def set_private_address
        Antfarm::Helpers.log :debug, 'IpNetwork#set_private_address called'
      end

      def merge_layer3_networks
        Antfarm::Helpers.log :debug, 'IpNetwork#merge_layer3_networks called'

        # Merge any existing networks already in the database that are
        # sub_networks of this new network.
        Layer3Network.merge(self.layer3_network, 0.80)
      end
    end
  end
end
