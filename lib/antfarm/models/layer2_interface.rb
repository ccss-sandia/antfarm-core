module Antfarm
  module Model
    class Layer2Interface
      include DataMapper::Resource

      storage_names[:default] = 'layer2_interfaces'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :media_type,       String
      property :custom,           String

#     has n,     :layer3_interfaces
#     has 1,     :ethernet_interface, :child_key => [:id]
      belongs_to :node, :required => true

      validates_present :certainty_factor

      # Need to do this before validation
      # since :nullable => false is specified
      # on the node association above.
      before :valid?, :create_node
      before :save,   :clamp_certainty_factor
#     after  :save,   :destroy_orphaned_nodes # TODO: be sure to write test if used!

      #######
      private
      #######

      # If a hash is passed into the node variable,
      # parameters matching variables on the node
      # class will be used to create a new node object.
      def create_node
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] Layer2Interface#create_node'

        # Only do anything with given node if
        # Layer 2 Interface is a new record.
        # Makes sense since this method used to
        # be called by before :create callback.
        self.node ||= Antfarm::Model::Node.create if new?
      end

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] Layer2Interface#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end

      def destroy_orphaned_nodes
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] Layer2Interface#destroy_orphaned_nodes'

        Node.all.each do |n|
          if n.layer2_interfaces.empty?
            Antfarm::Helpers.log :debug, "Layer2Interface - destroying orphaned node #{node}"
            n.destroy
          end
        end
      end
    end
  end
end
