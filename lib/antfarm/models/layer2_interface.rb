module Antfarm
  module Models
    class Layer2Interface
      include DataMapper::Resource

      property :id, Serial

      has n,     :layer3_interfaces
      has 1,     :ethernet_interface, :child_key => [:id]
      belongs_to :node, :nullable => true

      before :create, :create_node
#     before :save,   :clamp_certainty_factor
      before :destroy do
        self.ethernet_interface.destroy
      end
      after :create do
        Antfarm::Helpers.log :debug, 'Just created a Layer2Interface'
      end
#     after :save, :destroy_orphaned_nodes

      #######
      private
      #######

      def create_node
        Antfarm::Helpers.log :debug, 'Layer2Interface#create_node called'
        self.node = DataStore[:node].nil? ? Node.create : DataStore.delete(:node)
      end

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, 'Layer2Interface#clamp_certainty_factor called'
      end

      def destroy_orphaned_nodes
        Antfarm::Helpers.log :debug, "Layer2Interface#destroy_orphaned_nodes called by #{caller}"

        Node.all.each do |n|
          if n.layer2_interfaces.empty?
            Antfarm::Helpers.log :debug, 'Layer2Interface - destroying orphaned node'
            n.destroy
          end
        end
      end
    end
  end
end
