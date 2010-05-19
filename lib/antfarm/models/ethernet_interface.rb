module Antfarm
  module Model
    class EthernetInterface
      include DataMapper::Resource

      storage_names[:default] = 'ethernet_interfaces'

      property :id,      Serial
      property :address, String, :required => true
      property :custom,  String

      # TODO: use 'id' as key variable
      #
      # Right now it's creating a 'layer2_interface_id'
      # column in the table. Previously, we were just
      # using the 'id' column. Is that possible in
      # DataMapper? <scrapcoder>
      #
      # TODO: what's up with 'layer2interface_id = nil'?
      #
      # When a new ethernet interface object is created
      # in irb, a 'layer2interface_id' instance variable
      # is created, along with the 'layer2_interface_id'
      # variable that matches the table column. The model
      # is not valid when created because 'layer2interface_id'
      # ends up being nil. Note that if I modify the
      # Layer2Interface model to use the option ':child_key => :id'
      # on the 'has 1 :ethernet_interface' definition then
      # this model no longer has the weird 'layer2interface_id'
      # instance variable. However, when I do that and I
      # create a Layer2Interface by itself, the next time I
      # create an EthernetInterface, its layer 2 interface
      # won't point back to it... <scrapcoder>
      belongs_to :layer_two_interface, :required => true

      # Need to do this before validation
      # since :required => true is specified
      # on the layer 2 interface association
      # above.
      before :valid?, :create_layer_two_interface

      # This ensures that the MAC address entered
      # is of the right format. It is called
      # *before* the before_create method below
      # is called, which keeps the Layer2Interface
      # from being created if the address format
      # is not valid.
      #
      # TODO: this is now called AFTER the
      # create_layer2_interface method is
      # called above, so a layer 2 interface
      # will be created either way. Is this
      # really a problem, or do we care if
      # a layer 2 interface exists without
      # an ethernet interface, since that's
      # the default anyway?
      validates_format :address, :with => %r{^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$},
                                 :message => 'invalid MAC address format'

      #######
      private
      #######

      # If a hash is passed into the layer2_interface
      # variable, parameters matching variables on the
      # layer 2 interface class will be used to create
      # a new layer 2 interface object. This also works
      # for nested hashes - i.e. if the hash passed into
      # the layer2_interface variable contains a 'node'
      # key that has a hash as a value, parameters in
      # that hash that match variables on the node class
      # will be used to create the node created by the
      # layer 2 interface. w00t!
      def create_layer_two_interface
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] EthernetInterface#create_layer_two_interface'

        # Only create a new layer 2 interface if
        # a layer 2 interface  model isn't already
        # associated with this model. This protects
        # against new layer 2 interfaces being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a layer 2 interface
        # will be automatically created and associated
        # with this model on creation).
        self.layer_two_interface ||= Antfarm::Model::LayerTwoInterface.create
      end
    end
  end
end
