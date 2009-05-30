module Antfarm
  module Models
    class Layer3Interface
      include DataMapper::Resource

      property :id, Serial

      has 1,     :ip_interface, :child_key => [:id]
      belongs_to :layer2_interface
      belongs_to :layer3_network

      before :create, :create_layer2_interface
      before :create, :create_layer3_network
      before :save,   :clamp_certainty_factor

      private

      def create_layer2_interface
        puts 'Layer3Interface#create_layer2_interface called'
        unless self.layer2_interface
          self.layer2_interface = Layer2Interface.create
        end
      end

      def create_layer3_network
        puts 'Layer3Interface#create_layer3_network called'
        unless self.layer3_network
          self.layer3_network = Layer3Network.create
        end
      end

      def clamp_certainty_factor
        puts 'Layer3Interface#clamp_certainty_factor called'
      end
    end
  end
end
