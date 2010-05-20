module Antfarm
  module Model
    class IpNetwork
      include DataMapper::Resource

      storage_names[:default] = 'ip_networks'

      property :id,                 Serial
      property :address,            String, :required => true
      property :custom,             String

      belongs_to :layer_three_network, :required => true

      before :valid?, :create_layer_three_network
      after  :create, :merge_layer_three_networks

      validates_format :address,
        :with    => %r{\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}(?:\/[1-3]\d)?\z},
        :message => 'invalid IP network format'

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

      def merge_layer_three_networks
        # Merge any existing networks already in the database that are
        # sub_networks of this new network.
        LayerThreeNetwork.merge(self.layer_three_network, 0.80)
      end
    end
  end
end
