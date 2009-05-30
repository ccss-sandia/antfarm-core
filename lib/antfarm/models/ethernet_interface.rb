module Antfarm
  module Models
    class EthernetInterface
      include DataMapper::Resource

      property :id,      Serial
      property :address, String, :nullable => false

      belongs_to :layer2_interface, :child_key => [:id]

      validates_present :address

      before :create, :create_layer2_interface

      private

      def create_layer2_interface
        puts 'EthernetInterface#create_layer2_interface called'
        self.layer2_interface = Layer2Interface.create
      end
    end
  end
end
