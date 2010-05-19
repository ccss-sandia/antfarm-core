module Antfarm
  module Model
    class LayerThreeInterface
      include DataMapper::Resource

      storage_names[:default] = 'layer_three_interfaces'

      property :id,               Serial
      property :certainty_factor, Float, :required => true, :default => 0.8
      property :protocol,         String
      property :custom,           String

      belongs_to :layer_two_interface, :required => true

      validates_present :certainty_factor

      # Need to do this before validation
      # since :required => true is specified
      # on the layer 2 interface association
      # above.
      before :valid?, :create_layer_two_interface
      before :save,   :clamp_certainty_factor

      #######
      private
      #######

      # If a hash is passed into the layer 2 interface variable,
      # parameters matching variables on the layer 2 interface
      # class will be used to create a new layer 2 interface object.
      def create_layer_two_interface
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerThreeInterface#create_layer_two_interface'

        # Only create a new layer 2 interface if a
        # layer 2 interface model isn't already
        # associated with this model. This protects
        # against new layer 2 interfaces being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a layer 2 interface
        # will be automatically created and
        # associated with this model on creation).
        self.layer_two_interface ||= Antfarm::Model::LayerTwoInterface.create
      end

      def clamp_certainty_factor
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] LayerThreeInterface#clamp_certainty_factor'
        self.certainty_factor = Antfarm::Helpers.clamp(self.certainty_factor)
      end
    end
  end
end
