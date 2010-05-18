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
      has 1,     :ethernet_interface, :child_key => :id, :constraint => :destroy
#     has 1,     :ethernet_interface, :constraint => :destroy
      belongs_to :node, :required => true

      validates_present :certainty_factor

      # Need to do this before validation
      # since :required => true is specified
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

        # Only create a new node if a node model
        # isn't already associated with this model.
        # This protects against new nodes being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a node will be
        # automatically created and associated with
        # this model on creation).
        self.node ||= Antfarm::Model::Node.create
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
