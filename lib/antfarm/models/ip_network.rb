module Antfarm
  module Model
    class IpNetwork
      include DataMapper::Resource

      storage_names[:default] = 'ip_networks'

      property :id, Serial

      # I turn auto_validation off here since we are manually
      # validating that an address was provided below in the
      # 'validates_with_block' declaration below. Read below
      # for why we do this manually...
      property :address, String, :required => true, :auto_validation => false
      property :custom,  String

      # See the IpInterface model for an explanation of why we're doing this.
      property :layer_three_network_id, Integer, :required => true, :auto_validation => false

      belongs_to :layer_three_network #, :required => true, :auto_validation => false

      before :create, :create_layer_three_network
      after  :create, :merge_layer_three_networks

#     validates_format :address,
#       :with    => %r{\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}(?:\/[1-3]\d)?\z},
#       :message => 'invalid IP network format'

      # We're doing all the validations here manually
      # (rather than using the shortcuts above) so they
      # will be executed in order. If the shortcut methods
      # are used, this validation is ran first so when
      # an invalid address is given the @ip_net object
      # doesn't exist and NoMethodErrors are thrown.
      validates_with_block :address do
        format    = %r{\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}(?:\/[1-3]\d)?\z}
        @ip_net ||= Antfarm::IPAddrExt.new(self.address) rescue nil

        if self.address.nil?
          [ false, 'must be present' ]
        elsif not self.address =~ format
          [ false, 'invalid IP network format' ]
        elsif @ip_net.loopback_address?
          [ false, 'loopback address not allowed' ]
        else
          true
        end
      end

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
