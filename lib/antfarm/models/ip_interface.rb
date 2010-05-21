module Antfarm
  module Model
    class IpInterface
      include DataMapper::Resource

      storage_names[:default] = 'ip_interfaces'

      property :id, Serial

      # I turn auto_validation off here since we are manually
      # validating that an address was provided below in the
      # 'validates_with_block' declaration below. Read below
      # for why we do this manually...
      property :address, String,  :required => true, :auto_validation => false
      property :virtual, Boolean, :required => true, :default => false
      property :custom,  String

      # So right now we have a problem... currently we do NOT
      # want to create a layer 3 interface (and consequently
      # an IP network and layer 3 network) if the data given
      # for a new IP interface is not valid. This can be done
      # by requiring a layer_three_interface_id to exist for
      # an IpInterface, but not auto-validating, which will
      # allow us to validate the data given BEFORE creating
      # a new layer 3 interface. However, currently the
      # 'belongs_to' method does not act on ':auto_validation'
      # (it will in a future dm-validations release) so we
      # have to specify the 'layer_three_interface_id' property
      # explicitly here until the new version is out. For more
      # information, see the GitHub Gist and comments between
      # dkubb and ccss-sandia.
      property :layer_three_interface_id, Integer, :required => true, :auto_validation => false

      belongs_to :layer_three_interface #, :required => true, :auto_validation => false

      before :create, :create_layer_three_interface

#     validates_format :address,
#       :with    => %r{\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}(?:\/[1-3]\d)?\z},
#       :message => 'invalid IP address format'

      # We're doing all the validations here manually
      # (rather than using the shortcuts above) so they
      # will be executed in order. If the shortcut methods
      # are used, this validation is ran first so when
      # an invalid address is given the @ip_addr object
      # doesn't exist and NoMethodErrors are thrown.
      validates_with_block :address do
        format     = %r{\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}(?:\/[1-3]\d)?\z}
        @ip_addr ||= Antfarm::IPAddrExt.new(self.address) rescue nil

        if self.address.nil?
          [ false, 'must be present' ]
        elsif not self.address =~ format
          [ false, 'invalid IP address format' ]
        elsif @ip_addr.loopback_address?
          [ false, 'loopback address not allowed' ]
        elsif not @ip_addr.private_address?
          # If the address is public and it already exists in the database, don't create
          # a new one but still create a new IP Network just in case the data given for
          # this address includes more detailed information about its network.
          #
          # TODO: what should we do about multiple private networks?
          # Right now, multiple private interfaces of the same address can exist,
          # but they will just be associated with the same private network...
          if interface = Antfarm::Model::IpInterface.find_by_address(self.address)
            create_ip_network
            [ false, "#{self.address} already exits, but a new IP network was created anyway" ]
          else
            true
          end
        else
          true
        end
      end

      #######
      private
      #######

      def create_layer_three_interface
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] IpInterface#create_layer_three_interface'

        self.layer_three_interface ||= Antfarm::Model::LayerThreeInterface.create :layer_three_network => create_ip_network
      end

      def create_ip_network
        Antfarm::Helpers.log :debug, '[PRIVATE METHOD CALLED] IpInterface#create_ip_network'

        @ip_addr ||= Antfarm::IPAddrExt.new(self.address) rescue return nil

        network = Antfarm::Model::LayerThreeNetwork.network_containing(@ip_addr.to_cidr_string)
        return network unless network.nil?

        net         = @ip_addr.clone
        net.netmask = net.netmask << 2 if net == net.network

        network = Antfarm::Model::IpNetwork.create :address => net.to_cidr_string
        return network.layer_three_network
      end
    end
  end
end
