module Antfarm
  module Models
    class Layer2Interface
      include DataMapper::Resource

      property :id, Serial

      has n,     :layer3_interfaces
      has 1,     :ethernet_interface, :child_key => [:id]
      belongs_to :node

      before :create, :create_node
      before :save,   :clamp_certainty_factor
      before :destroy do
        ethernet_interface.destroy
      end
#     after :save, :destroy_orphaned_nodes

      private

      def create_node
        puts 'Layer2Interface#create_node called'

        self.node = DataStore[:node] or Node.create
      end

      def clamp_certainty_factor
        puts 'Layer2Interface#clamp_certainty_factor called'
      end

      def destroy_orphaned_nodes
        puts 'Layer2Interface#destroy_orphaned_nodes called'
        puts caller

        Node.all.each do |n|
          if n.layer2_interfaces.empty?
            puts 'Layer2Interface - destroying orphaned node'
            n.destroy
          end
        end
      end
    end
  end
end
