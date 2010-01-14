module Antfarm
  module Models
    class Layer3Interface
      include DataMapper::Resource

      property :id, Serial

      has 1,     :ip_interface, :child_key => [:id]
      has n,     :incoming, :model => 'Traffic', :child_key => [:target_id]
      has n,     :outgoing, :model => 'Traffic', :child_key => [:source_id]
      belongs_to :layer2_interface, :nullable => true
      belongs_to :layer3_network,   :nullable => true

      before :create, :create_layer2_interface
      before :create, :create_layer3_network
      before :save,   :clamp_certainty_factor

      #######
      private
      #######

      def create_layer2_interface
        Antfarm::Helpers.log :debug, 'Layer3Interface#create_layer2_interface called'
        self.layer2_interface = DataStore[:layer2_interface].nil? ? Layer2Interface.create : DataStore.delete(:layer2_interface)
      end

      def create_layer3_network
        Antfarm::Helpers.log :debug, 'Layer3Interface#create_layer3_network called'
        self.layer3_network = DataStore[:layer3_network].nil? ? Layer3Network.create : DataStore.delete(:layer3_network)
      end

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, 'Layer3Interface#clamp_certainty_factor called'
      end
    end
  end
end
