module Antfarm
  module Model
    class IpInterface
      include DataMapper::Resource

      storage_names[:default] = 'ip_interfaces'

      property :id,                 Serial
      property :address,            String, :required => true
      property :custom,             String

      belongs_to :layer_three_interface, :required => true

#     before :valid?, :create_layer_three_network

      validates_format :address,
        :with    => %r{\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}(?:\/[1-3]\d)?\z},
        :message => 'invalid IP address format'

      #######
      private
      #######

      def create_layer_three_network
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] IpNetwork#create_layer_three_network'

        # Only create a new layer 3 network if
        # a layer 3 network  model isn't already
        # associated with this model. This protects
        # against new layer 3 networks being
        # created when one is already provided or
        # when this model is being saved rather
        # than created (since a layer 3 network
        # will be automatically created and associated
        # with this model on creation).
        self.layer_three_network ||= Antfarm::Model::LayerThreeNetwork.create
      end
    end
  end
end
